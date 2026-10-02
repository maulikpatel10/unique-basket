/**
 * Test-only environment defaults (P0-02).
 * The application has no fallback secrets, so tests supply explicit, non-production values.
 * Values already set in the environment take precedence.
 */
process.env.NODE_ENV = process.env.NODE_ENV || 'test';
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test_only_jwt_access_secret_not_for_production';
process.env.JWT_REFRESH_SECRET =
  process.env.JWT_REFRESH_SECRET || 'test_only_jwt_refresh_secret_not_for_production';
