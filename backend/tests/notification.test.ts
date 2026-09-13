import request from 'supertest';
import app from '../src/app';
import { prisma } from '../src/config/db';
import { generateAccessToken } from '../src/utils/jwt';

describe('Device Token Registration & Push Notifications Integration Tests', () => {
  let customerToken: string;
  let customerId: string;
  let managerToken: string;
  let managerId: string;

  beforeAll(async () => {
    // 1. Customer setup
    const user = await prisma.user.upsert({
      where: { phone: '+919999999999' },
      update: {},
      create: { phone: '+919999999999', name: 'Notify Customer' },
    });
    customerId = user.id;

    customerToken = generateAccessToken({
      id: user.id,
      role: 'customer',
      phone: user.phone,
    });

    // 2. Manager setup
    const managerUser = await prisma.adminUser.findUnique({
      where: { email: 'manager1@uniquebasket.com' },
      include: { managers: true },
    });

    if (!managerUser) {
      throw new Error('manager1@uniquebasket.com not found.');
    }

    managerId = managerUser.id;
    managerToken = generateAccessToken({
      id: managerUser.id,
      role: 'STORE_MANAGER',
      email: managerUser.email,
      storeId: managerUser.managers[0]?.storeId,
    });

    // Clean up pre-existing test tokens
    await prisma.deviceToken.deleteMany({
      where: { token: { in: ['mock_customer_token_fcm', 'mock_manager_token_fcm'] } },
    });
  });

  afterAll(async () => {
    await prisma.deviceToken.deleteMany({
      where: { token: { in: ['mock_customer_token_fcm', 'mock_manager_token_fcm'] } },
    });
    await prisma.$disconnect();
  });

  describe('Device Token Registration', () => {
    it('should successfully register a customer device token', async () => {
      const res = await request(app)
        .post('/api/v1/notifications/tokens')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({
          token: 'mock_customer_token_fcm',
          platform: 'ANDROID',
        });

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('success', true);
      expect(res.body.data).toHaveProperty('userId', customerId);
      expect(res.body.data).toHaveProperty('adminUserId', null);
    });

    it('should successfully register a store manager device token', async () => {
      const res = await request(app)
        .post('/api/v1/notifications/tokens')
        .set('Authorization', `Bearer ${managerToken}`)
        .send({
          token: 'mock_manager_token_fcm',
          platform: 'IOS',
        });

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('success', true);
      expect(res.body.data).toHaveProperty('userId', null);
      expect(res.body.data).toHaveProperty('adminUserId', managerId);
    });

    it('should reject token registration if parameters are missing or invalid', async () => {
      const res = await request(app)
        .post('/api/v1/notifications/tokens')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({
          token: '',
          platform: 'INVALID_PLATFORM_NAME',
        });

      expect(res.statusCode).toEqual(400);
      expect(res.body).toHaveProperty('success', false);
      expect(res.body).toHaveProperty('errorCode', 'MISSING_PARAMETERS');
    });
  });
});
