/**
 * Centralised validation for security-critical environment variables.
 * There are intentionally NO fallback values for secrets.
 */

const MIN_PRODUCTION_SECRET_LENGTH = 32;

// Values that must never be accepted as secrets (previous hard-coded fallbacks).
const KNOWN_INSECURE_SECRETS = ['fallback_access_secret', 'fallback_refresh_secret', 'secret'];

/**
 * Returns a required environment variable or throws if it is missing/empty.
 */
export function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value || value.trim() === '') {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

/**
 * Validates required configuration. Throws with a list of all problems found.
 * - JWT_SECRET and JWT_REFRESH_SECRET are required in every environment.
 * - Outside development/test they must be at least 32 characters, must not be a
 *   known insecure value, and must differ from each other.
 */
export function validateEnv(): void {
  const errors: string[] = [];
  const nodeEnv = process.env.NODE_ENV;
  const isDevOrTest = nodeEnv === 'development' || nodeEnv === 'test';

  for (const name of ['JWT_SECRET', 'JWT_REFRESH_SECRET']) {
    const value = process.env[name];
    if (!value || value.trim() === '') {
      errors.push(`${name} is required.`);
      continue;
    }
    if (!isDevOrTest) {
      if (value.length < MIN_PRODUCTION_SECRET_LENGTH) {
        errors.push(`${name} must be at least ${MIN_PRODUCTION_SECRET_LENGTH} characters outside development/test.`);
      }
      if (KNOWN_INSECURE_SECRETS.includes(value)) {
        errors.push(`${name} uses a known insecure value.`);
      }
    }
  }

  if (
    !isDevOrTest &&
    process.env.JWT_SECRET &&
    process.env.JWT_SECRET === process.env.JWT_REFRESH_SECRET
  ) {
    errors.push('JWT_SECRET and JWT_REFRESH_SECRET must be different.');
  }

  if (errors.length > 0) {
    throw new Error(`Invalid environment configuration:\n- ${errors.join('\n- ')}`);
  }
}
