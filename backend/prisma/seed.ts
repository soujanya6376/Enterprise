import { PrismaClient, Prisma } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  // Roles
  const adminRole = await prisma.role.upsert({
    where: { name: 'ADMIN' },
    update: {},
    create: { name: 'ADMIN', description: 'Full system access' },
  });
  await prisma.role.upsert({
    where: { name: 'USER' },
    update: {},
    create: { name: 'USER', description: 'Cashier — billing only' },
  });

  // Default admin
  const username = process.env.SEED_ADMIN_USERNAME || 'admin';
  const password = process.env.SEED_ADMIN_PASSWORD || 'Admin@123';
  const email = process.env.SEED_ADMIN_EMAIL || 'admin@example.com';
  const passwordHash = await bcrypt.hash(password, 10);

  await prisma.user.upsert({
    where: { username },
    update: {},
    create: { username, email, passwordHash, roleId: adminRole.id, isActive: true },
  });

  // Global tax
  const taxPct = new Prisma.Decimal(process.env.SEED_GLOBAL_TAX || '18');
  const existingTax = await prisma.globalTaxSetting.findFirst({ where: { isActive: true } });
  if (!existingTax) {
    await prisma.globalTaxSetting.create({ data: { percentage: taxPct, isActive: true } });
  }

  // Sample products
  const sample: Prisma.ProductCreateManyInput[] = [
    { name: 'Coffee', description: 'Hot Coffee', price: new Prisma.Decimal('100.00'), taxPercentage: new Prisma.Decimal('5.00') },
    { name: 'Pizza', description: 'Margherita', price: new Prisma.Decimal('250.00'), taxPercentage: new Prisma.Decimal('18.00') },
    { name: 'Water Bottle', description: '1L', price: new Prisma.Decimal('20.00'), taxPercentage: null },
  ];
  for (const p of sample) {
    const exists = await prisma.product.findFirst({ where: { name: p.name, deletedAt: null } });
    if (!exists) await prisma.product.create({ data: p });
  }

  console.log(`Seed complete. Admin login: ${username} / ${password}`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); });
