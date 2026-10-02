import { prisma } from '../config/db';
import { generateRefreshToken, verifyRefreshToken } from '../utils/jwt';
import { AppError } from '../utils/errors';

/** Refresh token lifetime; must match the JWT expiry in utils/jwt.ts. */
const REFRESH_TOKEN_TTL_MS = 7 * 24 * 60 * 60 * 1000;

export interface RefreshSubject {
  id: string;
  role: string;
  jti: string;
}

const invalidSession = () =>
  new AppError(401, 'INVALID_REFRESH_TOKEN', 'Invalid or expired refresh token. Please log in again.');

/**
 * Issues a refresh token backed by a server-side session row (P1-08), so it can be revoked.
 */
export async function issueRefreshToken(subject: { id: string; role: string }): Promise<string> {
  const isCustomer = subject.role === 'customer';
  const session = await prisma.refreshToken.create({
    data: {
      userId: isCustomer ? subject.id : null,
      adminUserId: isCustomer ? null : subject.id,
      expiresAt: new Date(Date.now() + REFRESH_TOKEN_TTL_MS),
    },
  });
  return generateRefreshToken({ id: subject.id, role: subject.role }, session.id);
}

/**
 * Verifies the refresh JWT and that its session exists, belongs to the subject,
 * is not revoked and not expired. Throws 401 INVALID_REFRESH_TOKEN otherwise.
 */
export async function validateRefreshToken(token: string): Promise<RefreshSubject> {
  let decoded: { id: string; role: string; jti?: string };
  try {
    decoded = verifyRefreshToken(token);
  } catch {
    throw invalidSession();
  }

  // Tokens issued before P1-08 carry no session id and are no longer accepted
  if (!decoded.jti) {
    throw invalidSession();
  }

  const session = await prisma.refreshToken.findUnique({ where: { id: decoded.jti } });
  const ownerId = decoded.role === 'customer' ? session?.userId : session?.adminUserId;
  if (!session || session.revokedAt || session.expiresAt <= new Date() || ownerId !== decoded.id) {
    throw invalidSession();
  }

  return { id: decoded.id, role: decoded.role, jti: decoded.jti };
}

/** Revokes a single refresh session (idempotent). */
export async function revokeRefreshSession(jti: string): Promise<void> {
  await prisma.refreshToken.updateMany({
    where: { id: jti, revokedAt: null },
    data: { revokedAt: new Date() },
  });
}
