import request from 'supertest';
import app from '../src/app';
import { prisma } from '../src/config/db';
import { generateAccessToken } from '../src/utils/jwt';

describe('Store & Location Management Integration Tests', () => {
  let superAdminToken: string;
  let managerToken: string;
  let customerToken: string;

  beforeAll(async () => {
    // Fetch actual seeded admin users from database to satisfy foreign key constraints
    const superAdminUser = await prisma.adminUser.findUnique({
      where: { email: 'superadmin@uniquebasket.com' },
    });

    const managerUser = await prisma.adminUser.findUnique({
      where: { email: 'manager1@uniquebasket.com' },
      include: { managers: true },
    });

    if (!superAdminUser || !managerUser) {
      throw new Error('Seeded admin users not found in database. Run db:seed before running tests.');
    }

    superAdminToken = generateAccessToken({
      id: superAdminUser.id,
      role: 'SUPER_ADMIN',
      email: superAdminUser.email,
    });

    managerToken = generateAccessToken({
      id: managerUser.id,
      role: 'STORE_MANAGER',
      email: managerUser.email,
      storeId: managerUser.managers[0]?.storeId,
    });

    // Create or update a temporary customer in DB
    const customerUser = await prisma.user.upsert({
      where: { phone: '+919999999999' },
      update: {},
      create: { phone: '+919999999999', name: 'Test Customer' },
    });

    customerToken = generateAccessToken({
      id: customerUser.id,
      role: 'customer',
      phone: customerUser.phone,
    });
  });

  afterAll(async () => {
    // Delete any test created stores
    await prisma.store.deleteMany({
      where: { storeId: 'TEST-STORE-999' },
    });
    // Remove audit logs related to tests
    await prisma.auditLog.deleteMany({
      where: { action: { in: ['CREATE_STORE', 'DEACTIVATE_STORE'] } },
    });
    await prisma.$disconnect();
  });

  describe('GET /api/v1/stores', () => {
    it('should list all stores for an authenticated customer', async () => {
      const res = await request(app)
        .get('/api/v1/stores')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('success', true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(3); // At least 3 seeded stores
    });

    it('should calculate distance and eligibility if lat/lng are provided', async () => {
      // Coordinate right at STORE-001 (Unique Basket - Central Store)
      // Lat: 12.971598, Lng: 77.594562
      const res = await request(app)
        .get('/api/v1/stores?lat=12.971598&lng=77.594562&fulfillment=DELIVERY')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('success', true);
      
      const centralStore = res.body.data.find((s: any) => s.storeId === 'STORE-001');
      expect(centralStore).toBeDefined();
      expect(centralStore.distanceKm).toBeCloseTo(0, 1);
      expect(centralStore.isEligible).toBe(true); // Distance 0 is <= 10km delivery radius
    });

    it('should show isEligible = false if customer coordinates are outside store delivery radius', async () => {
      // Coordinate far away from stores (e.g. Silk Board area, around 12.9176, 77.6244)
      // Hebbal store (STORE-003) is at 13.035356, 77.598789 (~13.4 km away), delivery radius 12.0km.
      // So STORE-003 should be marked as isEligible = false.
      const res = await request(app)
        .get('/api/v1/stores?lat=12.9176&lng=77.6244&fulfillment=DELIVERY')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.statusCode).toEqual(200);
      
      const northStore = res.body.data.find((s: any) => s.storeId === 'STORE-003');
      expect(northStore).toBeDefined();
      expect(northStore.isEligible).toBe(false); // 13.4 km is > 12 km radius
    });
  });

  describe('POST /api/v1/stores (CRUD RBAC)', () => {
    const newStorePayload = {
      storeId: 'TEST-STORE-999',
      name: 'Test Store CRUD',
      address: 'Test Address Line',
      city: 'Bangalore',
      state: 'Karnataka',
      pincode: '560001',
      latitude: 12.9715,
      longitude: 77.5945,
      deliveryRadiusKm: 5.0,
      phone: '+919999999900',
      openingTime: '09:00',
      closingTime: '21:00',
    };

    it('should allow Super Admin to create a new store', async () => {
      const res = await request(app)
        .post('/api/v1/stores')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send(newStorePayload);

      expect(res.statusCode).toEqual(201);
      expect(res.body).toHaveProperty('success', true);
      expect(res.body.data).toHaveProperty('storeId', 'TEST-STORE-999');

      // Assert audit log was recorded
      const log = await prisma.auditLog.findFirst({
        where: { action: 'CREATE_STORE' },
      });
      expect(log).toBeDefined();
      expect(log?.details).toContain('TEST-STORE-999');
    });

    it('should reject store creation by a Store Manager', async () => {
      const res = await request(app)
        .post('/api/v1/stores')
        .set('Authorization', `Bearer ${managerToken}`)
        .send({ ...newStorePayload, storeId: 'TEST-STORE-FAIL' });

      expect(res.statusCode).toEqual(403);
      expect(res.body).toHaveProperty('success', false);
    });

    it('should reject store creation by a customer', async () => {
      const res = await request(app)
        .post('/api/v1/stores')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({ ...newStorePayload, storeId: 'TEST-STORE-FAIL' });

      expect(res.statusCode).toEqual(403);
      expect(res.body).toHaveProperty('success', false);
    });
  });
});
