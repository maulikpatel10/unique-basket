import jwt from 'jsonwebtoken';
import { requireEnv } from '../config/validateEnv';

// Secrets are read at call time and have no default values (P0-02).
const accessSecret = (): string => requireEnv('JWT_SECRET');
const refreshSecret = (): string => requireEnv('JWT_REFRESH_SECRET');

export interface TokenPayload {
  id: string;
  role: 'customer' | 'SUPER_ADMIN' | 'STORE_MANAGER';
  phone?: string;
  email?: string;
  storeId?: string; // Store ID mapped to Store Manager
}

export function generateAccessToken(payload: TokenPayload): string {
  return jwt.sign(payload, accessSecret(), { expiresIn: '15m' });
}

export function generateRefreshToken(payload: { id: string; role: string }): string {
  return jwt.sign(payload, refreshSecret(), { expiresIn: '7d' });
}

export function verifyAccessToken(token: string): TokenPayload {
  return jwt.verify(token, accessSecret()) as TokenPayload;
}

export function verifyRefreshToken(token: string): { id: string; role: string } {
  return jwt.verify(token, refreshSecret()) as { id: string; role: string };
}
