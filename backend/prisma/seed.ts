import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';

dotenv.config();

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is not set in environment variables');
}

const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('Seeding database...');

  // 1. Clean existing records (Reverse order of dependencies)
  await prisma.auditLog.deleteMany({});
  await prisma.deviceToken.deleteMany({});
  await prisma.payment.deleteMany({});
  await prisma.orderItem.deleteMany({});
  await prisma.order.deleteMany({});
  await prisma.storeInventory.deleteMany({});
  await prisma.product.deleteMany({});
  await prisma.category.deleteMany({});
  await prisma.storeManager.deleteMany({});
  await prisma.adminUser.deleteMany({});
  await prisma.store.deleteMany({});
  await prisma.userAddress.deleteMany({});
  await prisma.user.deleteMany({});
  await prisma.deliverySettings.deleteMany({});
  await prisma.banner.deleteMany({});

  console.log('Cleared existing records.');

  // 2. Create System Delivery Settings
  const deliverySettings = await prisma.deliverySettings.create({
    data: {
      deliveryEnabled: true,
      deliveryFee: 30.00,
      freeDeliveryThreshold: 499.00,
      minimumOrderAmount: 199.00,
      codEnabled: true,
      codCharge: 20.00,
      minimumCodOrderAmount: 100.00,
      maximumCodOrderAmount: 5000.00,
      pickupCodEnabled: true,
    },
  });
  console.log('Seeded delivery settings:', deliverySettings);

  // 3. Create Admin Users
  const superAdminPassword = await bcrypt.hash('SuperSecretPassword123', 10);
  const managerPassword = await bcrypt.hash('ManagerPassword123', 10);

  const superAdmin = await prisma.adminUser.create({
    data: {
      email: 'superadmin@uniquebasket.com',
      passwordHash: superAdminPassword,
      name: 'Super Admin',
      role: 'SUPER_ADMIN',
    },
  });

  const manager1 = await prisma.adminUser.create({
    data: {
      email: 'manager1@uniquebasket.com',
      passwordHash: managerPassword,
      name: 'Central Store Manager',
      role: 'STORE_MANAGER',
    },
  });

  const manager2 = await prisma.adminUser.create({
    data: {
      email: 'manager2@uniquebasket.com',
      passwordHash: managerPassword,
      name: 'East Store Manager',
      role: 'STORE_MANAGER',
    },
  });

  console.log('Seeded admin users.');

  // 4. Create Stores
  const centralStore = await prisma.store.create({
    data: {
      storeId: 'STORE-001',
      name: 'Unique Basket - Central Store',
      address: '100 MG Road, Central Bangalore',
      city: 'Bangalore',
      state: 'Karnataka',
      pincode: '560001',
      latitude: 12.971598,
      longitude: 77.594562,
      deliveryRadiusKm: 10.00, // 10 km
      phone: '+919876543210',
      email: 'central@uniquebasket.com',
      openingTime: '08:00',
      closingTime: '22:00',
    },
  });

  const eastStore = await prisma.store.create({
    data: {
      storeId: 'STORE-002',
      name: 'Unique Basket - East Store',
      address: '200 Indiranagar Double Road, East Bangalore',
      city: 'Bangalore',
      state: 'Karnataka',
      pincode: '560038',
      latitude: 12.971891,
      longitude: 77.641151,
      deliveryRadiusKm: 8.00, // 8 km
      phone: '+919876543211',
      email: 'east@uniquebasket.com',
      openingTime: '08:00',
      closingTime: '22:00',
    },
  });

  const northStore = await prisma.store.create({
    data: {
      storeId: 'STORE-003',
      name: 'Unique Basket - North Store',
      address: '300 Hebbal Flyover, North Bangalore',
      city: 'Bangalore',
      state: 'Karnataka',
      pincode: '560024',
      latitude: 13.035356,
      longitude: 77.598789,
      deliveryRadiusKm: 12.00, // 12 km
      phone: '+919876543212',
      email: 'north@uniquebasket.com',
      openingTime: '08:00',
      closingTime: '22:00',
    },
  });

  console.log('Seeded stores.');

  // 5. Assign Managers to Stores
  await prisma.storeManager.createMany({
    data: [
      { adminUserId: manager1.id, storeId: centralStore.id },
      { adminUserId: manager2.id, storeId: eastStore.id },
    ],
  });
  console.log('Assigned store managers.');

  // 6. Create Categories
  const fruits = await prisma.category.create({
    data: {
      name: 'Fruits',
      imageUrl: 'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?auto=format&fit=crop&q=80&w=400',
      displayOrder: 1,
    },
  });

  const vegetables = await prisma.category.create({
    data: {
      name: 'Vegetables',
      imageUrl: 'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?auto=format&fit=crop&q=80&w=400',
      displayOrder: 2,
    },
  });

  const leafyVegetables = await prisma.category.create({
    data: {
      name: 'Leafy Vegetables',
      imageUrl: 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&q=80&w=400',
      displayOrder: 3,
    },
  });

  console.log('Seeded categories.');

  // 7. Create Products
  const productsData = [
    // Fruits
    { name: 'Apple (Shimla)', categoryId: fruits.id, price: 180.00, mrp: 220.00, unit: 'KG' as const, description: 'Fresh Shimla red apples directly from orchards.' },
    { name: 'Banana (Robusta)', categoryId: fruits.id, price: 60.00, mrp: 80.00, unit: 'DOZEN' as const, description: 'High quality sweet robusta bananas.' },
    
    // Vegetables
    { name: 'Potato (Jyoti)', categoryId: vegetables.id, price: 30.00, mrp: 40.00, unit: 'KG' as const, description: 'Fresh local farm potatoes.' },
    { name: 'Tomato (Local)', categoryId: vegetables.id, price: 40.00, mrp: 60.00, unit: 'KG' as const, description: 'Ripe local red tomatoes.' },
    
    // Leafy Vegetables
    { name: 'Spinach (Palak)', categoryId: leafyVegetables.id, price: 25.00, mrp: 35.00, unit: 'PACK' as const, description: 'Fresh, cleaned spinach pack.' },
  ];

  const products: any[] = [];
  for (const item of productsData) {
    const product = await prisma.product.create({
      data: item,
    });
    products.push(product);
  }
  console.log('Seeded products.');

  // 8. Create Store Inventories
  // Apples
  await prisma.storeInventory.createMany({
    data: [
      { storeId: centralStore.id, productId: products[0].id, stockQuantity: 50.000, lowStockThreshold: 10.000 },
      { storeId: eastStore.id, productId: products[0].id, stockQuantity: 30.000, lowStockThreshold: 5.000 },
      { storeId: northStore.id, productId: products[0].id, stockQuantity: 10.000, lowStockThreshold: 3.000 },
    ],
  });

  // Bananas
  await prisma.storeInventory.createMany({
    data: [
      { storeId: centralStore.id, productId: products[1].id, stockQuantity: 20.000, lowStockThreshold: 5.000 },
      { storeId: eastStore.id, productId: products[1].id, stockQuantity: 15.000, lowStockThreshold: 3.000 },
      { storeId: northStore.id, productId: products[1].id, stockQuantity: 5.000, lowStockThreshold: 2.000 },
    ],
  });

  // Potatoes
  await prisma.storeInventory.createMany({
    data: [
      { storeId: centralStore.id, productId: products[2].id, stockQuantity: 100.000, lowStockThreshold: 20.000 },
      { storeId: eastStore.id, productId: products[2].id, stockQuantity: 80.000, lowStockThreshold: 15.000 },
      { storeId: northStore.id, productId: products[2].id, stockQuantity: 20.000, lowStockThreshold: 5.000 },
    ],
  });

  // Tomatoes
  await prisma.storeInventory.createMany({
    data: [
      { storeId: centralStore.id, productId: products[3].id, stockQuantity: 80.000, lowStockThreshold: 15.000 },
      { storeId: eastStore.id, productId: products[3].id, stockQuantity: 50.000, lowStockThreshold: 10.000 },
      { storeId: northStore.id, productId: products[3].id, stockQuantity: 15.000, lowStockThreshold: 4.000 },
    ],
  });

  // Spinach
  await prisma.storeInventory.createMany({
    data: [
      { storeId: centralStore.id, productId: products[4].id, stockQuantity: 30.000, lowStockThreshold: 5.000 },
      { storeId: eastStore.id, productId: products[4].id, stockQuantity: 20.000, lowStockThreshold: 4.000 },
      { storeId: northStore.id, productId: products[4].id, stockQuantity: 8.000, lowStockThreshold: 2.000 },
    ],
  });

  console.log('Seeded store inventories.');

  // 9. Seed audit log
  await prisma.auditLog.create({
    data: {
      adminUserId: superAdmin.id,
      action: 'SYSTEM_INITIAL_SEED',
      details: 'Successfully executed system relational initial seeding.',
    },
  });

  console.log('Seeding completed successfully.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
