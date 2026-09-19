import request from 'supertest';
import app from '../src/app';
import { prisma } from '../src/config/db';
import { generateAccessToken } from '../src/utils/jwt';

describe('Customer Profile & Address API Integration Tests', () => {
  const testPhone = '+919988776655';
  let testUserId: string;
  let customerToken: string;
  let adminToken: string;

  beforeAll(async () => {
    // Clean up any pre-existing test customer
    await prisma.user.deleteMany({
      where: { phone: testPhone },
    });

    // Create test customer with no DOB
    const user = await prisma.user.create({
      data: {
        phone: testPhone,
        name: null,
        dob: null,
      },
    });
    testUserId = user.id;

    customerToken = generateAccessToken({
      id: user.id,
      role: 'customer',
      phone: user.phone,
    });

    // Fetch an existing super admin or create mock token
    const admin = await prisma.adminUser.findFirst({
      where: { role: 'SUPER_ADMIN', isActive: true },
    });

    adminToken = generateAccessToken({
      id: admin?.id || 'admin-test-id',
      role: 'SUPER_ADMIN',
      phone: admin?.phone || '+919999999999',
    });
  });

  afterAll(async () => {
    await prisma.user.deleteMany({
      where: { phone: testPhone },
    });
    await prisma.$disconnect();
  });

  describe('GET /api/v1/customer/profile', () => {
    it('should reject unauthenticated request', async () => {
      const res = await request(app).get('/api/v1/customer/profile');
      expect(res.statusCode).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('should return the authenticated customer profile with null dob initially', async () => {
      const res = await request(app)
        .get('/api/v1/customer/profile')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.id).toBe(testUserId);
      expect(res.body.data.user.phone).toBe(testPhone);
      expect(res.body.data.user.dob).toBeNull();
    });
  });

  describe('PUT /api/v1/customer/profile', () => {
    it('should update customer profile name and date of birth', async () => {
      const targetDob = '2000-08-15T00:00:00.000Z';
      const res = await request(app)
        .put('/api/v1/customer/profile')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({
          name: 'Aarav Sharma',
          dob: targetDob,
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.name).toBe('Aarav Sharma');
      expect(new Date(res.body.data.user.dob).toISOString()).toBe(targetDob);

      // Verify in PostgreSQL database directly
      const dbUser = await prisma.user.findUnique({
        where: { id: testUserId },
      });
      expect(dbUser?.name).toBe('Aarav Sharma');
      expect(dbUser?.dob).not.toBeNull();
      expect(dbUser?.dob?.toISOString()).toBe(targetDob);
    });

    it('should return saved DOB on subsequent GET /api/v1/customer/profile', async () => {
      const res = await request(app)
        .get('/api/v1/customer/profile')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.name).toBe('Aarav Sharma');
      expect(res.body.data.user.dob).toBe('2000-08-15T00:00:00.000Z');
    });

    it('should preserve calendar day without timezone shifting (15 Aug 2000)', async () => {
      const dbUser = await prisma.user.findUnique({
        where: { id: testUserId },
      });
      const date = dbUser!.dob!;
      expect(date.getUTCFullYear()).toBe(2000);
      expect(date.getUTCMonth()).toBe(7); // 0-indexed: 7 = August
      expect(date.getUTCDate()).toBe(15);
    });

    it('should reject invalid DOB format', async () => {
      const res = await request(app)
        .put('/api/v1/customer/profile')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({ dob: 'invalid-date-string' });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.errorCode).toBe('INVALID_DOB');
    });

    it('should reject future DOB', async () => {
      const futureDate = new Date(Date.now() + 86400000 * 365).toISOString();
      const res = await request(app)
        .put('/api/v1/customer/profile')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({ dob: futureDate });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.errorCode).toBe('FUTURE_DOB');
    });

    it('should reject empty name string', async () => {
      const res = await request(app)
        .put('/api/v1/customer/profile')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({ name: '   ' });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.errorCode).toBe('INVALID_NAME');
    });
  });

  describe('Admin Customer API DOB Verification', () => {
    it('should return DOB in admin customer list and details', async () => {
      const detailRes = await request(app)
        .get(`/api/v1/admin/customers/${testUserId}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(detailRes.statusCode).toBe(200);
      expect(detailRes.body.success).toBe(true);
      expect(detailRes.body.data.customer.id).toBe(testUserId);
      expect(detailRes.body.data.customer.dob).toBe('2000-08-15T00:00:00.000Z');
    });
  });

  describe('POST & GET /api/v1/customer/addresses', () => {
    it('should reject unauthenticated address creation', async () => {
      const res = await request(app).post('/api/v1/customer/addresses').send({
        addressLine: 'Flat 402, Royal Palms, Kalawad Road',
        pincode: '360005',
      });
      expect(res.statusCode).toBe(401);
    });

    it('should successfully save a customer address linked to the authenticated user', async () => {
      const res = await request(app)
        .post('/api/v1/customer/addresses')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({
          title: 'Home',
          addressLine: 'Flat 402, Royal Palms, Kalawad Road',
          city: 'Rajkot',
          state: 'Gujarat',
          pincode: '360005',
        });

      expect(res.statusCode).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.address.userId).toBe(testUserId);
      expect(res.body.data.address.pincode).toBe('360005');
      expect(res.body.data.address.city).toBe('Rajkot');
      expect(res.body.data.address.state).toBe('Gujarat');
      expect(res.body.data.address.isDefault).toBe(true);

      // Verify in PostgreSQL database
      const dbAddress = await prisma.userAddress.findFirst({
        where: { userId: testUserId },
      });
      expect(dbAddress).not.toBeNull();
      expect(dbAddress?.addressLine).toBe('Flat 402, Royal Palms, Kalawad Road');
    });

    it('should retrieve customer addresses list', async () => {
      const res = await request(app)
        .get('/api/v1/customer/addresses')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.addresses.length).toBeGreaterThanOrEqual(1);
      expect(res.body.data.addresses[0].userId).toBe(testUserId);
    });
  });
});
