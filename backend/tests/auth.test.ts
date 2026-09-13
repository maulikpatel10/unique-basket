import request from 'supertest';
import app from '../src/app';
import { prisma } from '../src/config/db';

describe('Authentication Flow Integration Tests', () => {
  const testPhone = '+919999999999';
  const testOtp = '123456'; // Default in development environment

  beforeAll(async () => {
    // Ensure any pre-existing test user is removed to assert new user flows
    await prisma.user.deleteMany({
      where: { phone: testPhone },
    });
  });

  afterAll(async () => {
    // Cleanup test user and close DB pool connections
    await prisma.user.deleteMany({
      where: { phone: testPhone },
    });
    await prisma.$disconnect();
  });

  describe('Customer OTP Flow', () => {
    it('should successfully send an OTP to a valid mobile number', async () => {
      const res = await request(app)
        .post('/api/v1/auth/send-otp')
        .send({ phone: testPhone });

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('success', true);
      expect(res.body).toHaveProperty('message');
    });

    it('should fail to send an OTP to an invalid mobile format', async () => {
      const res = await request(app)
        .post('/api/v1/auth/send-otp')
        .send({ phone: 'invalid-phone-string' });

      expect(res.statusCode).toEqual(400);
      expect(res.body).toHaveProperty('success', false);
      expect(res.body).toHaveProperty('errorCode', 'INVALID_PHONE_FORMAT');
    });

    it('should successfully verify a correct OTP and register a new user', async () => {
      const res = await request(app)
        .post('/api/v1/auth/verify-otp')
        .send({ phone: testPhone, otp: testOtp });

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('success', true);
      expect(res.body.data).toHaveProperty('isNewUser', true);
      expect(res.body.data).toHaveProperty('token');
      expect(res.body.data).toHaveProperty('refreshToken');
      expect(res.body.data.user).toHaveProperty('phone', testPhone);
    });

    it('should fail when verifying with an incorrect OTP code', async () => {
      const res = await request(app)
        .post('/api/v1/auth/verify-otp')
        .send({ phone: testPhone, otp: '999999' });

      expect(res.statusCode).toEqual(400);
      expect(res.body).toHaveProperty('success', false);
      expect(res.body).toHaveProperty('errorCode', 'OTP_VERIFICATION_FAILED');
    });
  });

  describe('Admin Login Flow', () => {
    it('should successfully authenticate super admin credentials', async () => {
      const res = await request(app)
        .post('/api/v1/admin/login')
        .send({
          email: 'superadmin@uniquebasket.com',
          password: 'SuperSecretPassword123',
        });

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('success', true);
      expect(res.body.data.admin).toHaveProperty('role', 'SUPER_ADMIN');
      expect(res.body.data).toHaveProperty('token');
    });

    it('should successfully authenticate store manager credentials and return assigned storeId', async () => {
      const res = await request(app)
        .post('/api/v1/admin/login')
        .send({
          email: 'manager1@uniquebasket.com',
          password: 'ManagerPassword123',
        });

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('success', true);
      expect(res.body.data.admin).toHaveProperty('role', 'STORE_MANAGER');
      expect(res.body.data.admin).toHaveProperty('storeId');
      expect(res.body.data.admin.storeId).not.toBeNull();
    });

    it('should reject login for incorrect administrative password', async () => {
      const res = await request(app)
        .post('/api/v1/admin/login')
        .send({
          email: 'superadmin@uniquebasket.com',
          password: 'WrongPassword',
        });

      expect(res.statusCode).toEqual(401);
      expect(res.body).toHaveProperty('success', false);
      expect(res.body).toHaveProperty('errorCode', 'INVALID_CREDENTIALS');
    });
  });
});
