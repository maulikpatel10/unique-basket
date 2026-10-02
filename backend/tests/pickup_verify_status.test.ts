import request from 'supertest';
import app from '../src/app';
import { prisma } from '../src/config/db';
import { generateAccessToken } from '../src/utils/jwt';
import { OrderStatus, PaymentStatus } from '@prisma/client';

// P0-04: Pickup handover is only allowed from READY_FOR_PICKUP.
describe('Pickup verification status guard (P0-04)', () => {
  const customerPhone = '+919888800004';
  let customerId: string;
  let storeId: string;
  let managerToken: string;
  let seq = 0;

  const createPickupOrder = async (orderStatus: OrderStatus, paymentStatus: PaymentStatus = PaymentStatus.PENDING) => {
    seq += 1;
    return prisma.order.create({
      data: {
        orderNumber: `#UB-P004-${Date.now()}-${seq}`,
        userId: customerId,
        storeId,
        fulfillmentType: 'PICKUP',
        subtotal: 100,
        deliveryFee: 0,
        codCharge: 0,
        total: 100,
        paymentMethod: 'COD',
        paymentStatus,
        orderStatus,
      },
    });
  };

  const verify = (orderNumber: string) =>
    request(app)
      .post('/api/v1/admin/orders/pickup-verify')
      .set('Authorization', `Bearer ${managerToken}`)
      .send({ orderNumber, phone: customerPhone });

  beforeAll(async () => {
    const manager = await prisma.adminUser.findUnique({
      where: { email: 'manager1@uniquebasket.com' },
      include: { managers: true },
    });
    if (!manager || manager.managers.length === 0) {
      throw new Error('Seeded manager1 with a store assignment not found.');
    }
    storeId = manager.managers[0].storeId;

    const user = await prisma.user.upsert({
      where: { phone: customerPhone },
      update: {},
      create: { phone: customerPhone, name: 'Pickup Guard Customer' },
    });
    customerId = user.id;

    managerToken = generateAccessToken({
      id: manager.id,
      role: 'STORE_MANAGER',
      email: manager.email,
      storeId,
    });
  });

  afterAll(async () => {
    await prisma.order.deleteMany({ where: { userId: customerId } });
    await prisma.user.deleteMany({ where: { id: customerId } });
    await prisma.$disconnect();
  });

  it.each([
    [OrderStatus.PLACED],
    [OrderStatus.CONFIRMED],
    [OrderStatus.PREPARING],
    [OrderStatus.CANCELLED],
    [OrderStatus.PICKED_UP],
  ])('rejects handover for a %s order and leaves it unchanged', async (status) => {
    const order = await createPickupOrder(status);

    const res = await verify(order.orderNumber);

    expect(res.statusCode).toEqual(400);
    expect(res.body).toHaveProperty('success', false);
    expect(res.body).toHaveProperty('errorCode', 'ORDER_NOT_READY_FOR_PICKUP');

    const after = await prisma.order.findUniqueOrThrow({ where: { id: order.id } });
    expect(after.orderStatus).toEqual(status);
    expect(after.paymentStatus).toEqual(PaymentStatus.PENDING);
  });

  it('allows handover for a READY_FOR_PICKUP order', async () => {
    const order = await createPickupOrder(OrderStatus.READY_FOR_PICKUP);

    const res = await verify(order.orderNumber);

    expect(res.statusCode).toEqual(200);
    expect(res.body.data).toHaveProperty('orderStatus', 'PICKED_UP');
    expect(res.body.data).toHaveProperty('paymentStatus', 'PAID');
  });

  it('hands over only once when verified concurrently', async () => {
    const order = await createPickupOrder(OrderStatus.READY_FOR_PICKUP);

    const results = await Promise.all([verify(order.orderNumber), verify(order.orderNumber)]);
    const statuses = results.map((r) => r.statusCode).sort();

    expect(statuses.filter((s) => s === 200)).toHaveLength(1);
    // The loser sees either the pre-check (400) or the conditional update conflict (409)
    expect([400, 409]).toContain(statuses.find((s) => s !== 200));

    const handoverLogs = await prisma.auditLog.count({
      where: { action: 'VERIFY_PICKUP_HANDOVER', details: { contains: order.orderNumber } },
    });
    expect(handoverLogs).toEqual(1);

    await prisma.auditLog.deleteMany({
      where: { action: 'VERIFY_PICKUP_HANDOVER', details: { contains: '#UB-P004-' } },
    });
  });
});
