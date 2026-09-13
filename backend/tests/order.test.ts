import request from 'supertest';
import app from '../src/app';
import { prisma } from '../src/config/db';
import { generateAccessToken } from '../src/utils/jwt';

describe('Cart & Order Placement Integration Tests', () => {
  let customerToken: string;
  let customerId: string;

  let centralStoreId: string;
  let appleProductId: string;

  let nearAddressId: string;
  let farAddressId: string;

  beforeAll(async () => {
    // 1. Create or load test customer
    const user = await prisma.user.upsert({
      where: { phone: '+919999999999' },
      update: {},
      create: { phone: '+919999999999', name: 'Test Order Customer' },
    });
    customerId = user.id;

    customerToken = generateAccessToken({
      id: user.id,
      role: 'customer',
      phone: user.phone,
    });

    // 2. Fetch seeded store and product
    const store = await prisma.store.findUnique({
      where: { storeId: 'STORE-001' },
    });
    if (!store) throw new Error('Seeded central store STORE-001 not found.');
    centralStoreId = store.id;

    const apple = await prisma.product.findFirst({
      where: { name: { startsWith: 'Apple' } },
    });
    if (!apple) throw new Error('Seeded Apple product not found.');
    appleProductId = apple.id;

    // Reset store stock for Apple to exactly 50.00
    await prisma.storeInventory.upsert({
      where: {
        storeId_productId: { storeId: centralStoreId, productId: appleProductId },
      },
      update: { stockQuantity: 50.00 },
      create: { storeId: centralStoreId, productId: appleProductId, stockQuantity: 50.00 },
    });

    // 3. Create test addresses
    const nearAddr = await prisma.userAddress.create({
      data: {
        userId: customerId,
        title: 'Near Central Store',
        addressLine: '101 MG Road',
        city: 'Bangalore',
        state: 'Karnataka',
        pincode: '560001',
        latitude: 12.971598,
        longitude: 77.594562, // 0 km distance
      },
    });
    nearAddressId = nearAddr.id;

    const farAddr = await prisma.userAddress.create({
      data: {
        userId: customerId,
        title: 'Far Out of Bounds',
        addressLine: 'Rural area out of range',
        city: 'Out of town',
        state: 'Karnataka',
        pincode: '570001',
        latitude: 12.000000,
        longitude: 77.000000, // Very far away
      },
    });
    farAddressId = farAddr.id;
  });

  afterAll(async () => {
    // Cleanup created orders, payments, addresses, cart items
    await prisma.orderItem.deleteMany({
      where: { order: { userId: customerId } },
    });
    await prisma.payment.deleteMany({
      where: { order: { userId: customerId } },
    });
    await prisma.order.deleteMany({
      where: { userId: customerId },
    });
    await prisma.userAddress.deleteMany({
      where: { userId: customerId },
    });
    await prisma.cartItem.deleteMany({
      where: { userId: customerId },
    });
    await prisma.auditLog.deleteMany({
      where: { action: { in: ['CREATE_ORDER', 'CANCEL_ORDER'] } },
    });
    await prisma.$disconnect();
  });

  describe('Cart Endpoints (GET, POST, PUT, DELETE)', () => {
    it('should add a decimal quantity item to the cart', async () => {
      const res = await request(app)
        .post('/api/v1/cart/items')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({
          productId: appleProductId,
          quantity: 1.5,
        });

      expect(res.statusCode).toEqual(201);
      expect(res.body).toHaveProperty('success', true);
      expect(res.body.data).toHaveProperty('quantity', 1.5);
    });

    it('should get current cart summary and subtotal', async () => {
      const res = await request(app)
        .get('/api/v1/cart')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('success', true);
      expect(res.body.data.items.length).toEqual(1);
      
      const appleItem = res.body.data.items[0];
      expect(appleItem.productId).toEqual(appleProductId);
      // Apple price is 180.00, quantity is 1.5 -> total price = 270.00
      expect(appleItem.totalPrice).toEqual(270);
      expect(res.body.data.subtotal).toEqual(270);
    });
  });

  describe('Order Creation & Stock Updates', () => {
    it('should reject delivery checkout if coordinates are out of bounds', async () => {
      const res = await request(app)
        .post('/api/v1/orders')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({
          fulfillmentType: 'DELIVERY',
          addressId: farAddressId,
          paymentMethod: 'COD',
          items: [{ productId: appleProductId, quantity: 2.0 }],
        });

      expect(res.statusCode).toEqual(400);
      expect(res.body).toHaveProperty('success', false);
      expect(res.body).toHaveProperty('errorCode', 'NO_DELIVERY_AVAILABLE');
    });

    it('should successfully place a delivery order, assign nearest store, and decrement stock', async () => {
      // Prior stock is 50.00
      const res = await request(app)
        .post('/api/v1/orders')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({
          fulfillmentType: 'DELIVERY',
          addressId: nearAddressId,
          paymentMethod: 'COD',
          items: [{ productId: appleProductId, quantity: 2.5 }],
        });

      expect(res.statusCode).toEqual(201);
      expect(res.body).toHaveProperty('success', true);
      expect(res.body.data.order).toHaveProperty('orderStatus', 'PLACED');

      // Assert inventory decreased by 2.5 (from 50.00 -> 47.50)
      const inv = await prisma.storeInventory.findUnique({
        where: {
          storeId_productId: { storeId: centralStoreId, productId: appleProductId },
        },
      });
      expect(Number(inv?.stockQuantity)).toEqual(47.50);
    });

    it('should fail checkout if requested quantity exceeds available stock', async () => {
      // Current stock is 47.50. Let's request 100.00 KG of Apples.
      const res = await request(app)
        .post('/api/v1/orders')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({
          fulfillmentType: 'DELIVERY',
          addressId: nearAddressId,
          paymentMethod: 'COD',
          items: [{ productId: appleProductId, quantity: 100.00 }],
        });

      expect(res.statusCode).toEqual(400);
      expect(res.body).toHaveProperty('success', false);
      expect(res.body).toHaveProperty('errorCode', 'INSUFFICIENT_STOCK');
    });
  });
});
