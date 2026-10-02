import { validateEnv, requireEnv } from '../src/config/validateEnv';
import { generateAccessToken, verifyAccessToken, generateRefreshToken, verifyRefreshToken } from '../src/utils/jwt';

describe('Environment validation and JWT secrets (P0-02)', () => {
  const saved = {
    NODE_ENV: process.env.NODE_ENV,
    JWT_SECRET: process.env.JWT_SECRET,
    JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET,
  };

  const strongAccess = 'a'.repeat(40);
  const strongRefresh = 'b'.repeat(40);

  afterEach(() => {
    for (const [key, value] of Object.entries(saved)) {
      if (value === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = value;
      }
    }
  });

  describe('validateEnv', () => {
    it('fails when JWT secrets are missing, in every environment', () => {
      for (const env of [undefined, 'production', 'development', 'test']) {
        if (env === undefined) delete process.env.NODE_ENV;
        else process.env.NODE_ENV = env;
        delete process.env.JWT_SECRET;
        delete process.env.JWT_REFRESH_SECRET;

        expect(() => validateEnv()).toThrow(/JWT_SECRET is required/);
        expect(() => validateEnv()).toThrow(/JWT_REFRESH_SECRET is required/);
      }
    });

    it('rejects short secrets outside development/test (including unset NODE_ENV)', () => {
      for (const env of [undefined, 'production', 'staging']) {
        if (env === undefined) delete process.env.NODE_ENV;
        else process.env.NODE_ENV = env;
        process.env.JWT_SECRET = 'short';
        process.env.JWT_REFRESH_SECRET = strongRefresh;

        expect(() => validateEnv()).toThrow(/JWT_SECRET must be at least 32 characters/);
      }
    });

    it('rejects the previous hard-coded values outside development/test', () => {
      process.env.NODE_ENV = 'production';
      process.env.JWT_SECRET = 'fallback_access_secret';
      process.env.JWT_REFRESH_SECRET = 'fallback_refresh_secret';

      expect(() => validateEnv()).toThrow(/known insecure value/);
    });

    it('rejects identical access and refresh secrets outside development/test', () => {
      process.env.NODE_ENV = 'production';
      process.env.JWT_SECRET = strongAccess;
      process.env.JWT_REFRESH_SECRET = strongAccess;

      expect(() => validateEnv()).toThrow(/must be different/);
    });

    it('accepts strong, distinct secrets in production', () => {
      process.env.NODE_ENV = 'production';
      process.env.JWT_SECRET = strongAccess;
      process.env.JWT_REFRESH_SECRET = strongRefresh;

      expect(() => validateEnv()).not.toThrow();
    });

    it('accepts any non-empty secrets in development', () => {
      process.env.NODE_ENV = 'development';
      process.env.JWT_SECRET = 'dev';
      process.env.JWT_REFRESH_SECRET = 'dev-refresh';

      expect(() => validateEnv()).not.toThrow();
    });
  });

  describe('requireEnv', () => {
    it('throws for missing or blank values', () => {
      delete process.env.JWT_SECRET;
      expect(() => requireEnv('JWT_SECRET')).toThrow(/Missing required environment variable: JWT_SECRET/);
      process.env.JWT_SECRET = '   ';
      expect(() => requireEnv('JWT_SECRET')).toThrow(/JWT_SECRET/);
    });
  });

  describe('JWT utilities have no fallback secrets', () => {
    it('cannot sign or verify tokens when secrets are missing', () => {
      delete process.env.JWT_SECRET;
      delete process.env.JWT_REFRESH_SECRET;

      expect(() => generateAccessToken({ id: 'u1', role: 'customer' })).toThrow(/JWT_SECRET/);
      expect(() => generateRefreshToken({ id: 'u1', role: 'customer' })).toThrow(/JWT_REFRESH_SECRET/);
      expect(() => verifyAccessToken('any.token.value')).toThrow(/JWT_SECRET/);
      expect(() => verifyRefreshToken('any.token.value')).toThrow(/JWT_REFRESH_SECRET/);
    });

    it('rejects tokens signed with the old fallback secret', () => {
      process.env.JWT_SECRET = strongAccess;
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const jwt = require('jsonwebtoken');
      const forged = jwt.sign({ id: 'admin', role: 'SUPER_ADMIN' }, 'fallback_access_secret');

      expect(() => verifyAccessToken(forged)).toThrow();
    });

    it('round-trips tokens with the configured secret', () => {
      process.env.JWT_SECRET = strongAccess;
      const token = generateAccessToken({ id: 'u1', role: 'customer', phone: '+919999999999' });
      expect(verifyAccessToken(token)).toMatchObject({ id: 'u1', role: 'customer' });
    });
  });
});
