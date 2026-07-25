import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { TaxService } from '../tax/tax.service';
import { buildMeta } from '../../common/dto/pagination.dto';
import { computeLine, computeOrderTotals } from '../../common/utils/money.util';
import { CreateOrderDto, OrderQueryDto } from './dto/order.dto';

@Injectable()
export class OrdersService {
  constructor(private prisma: PrismaService, private tax: TaxService) {}

  /** Generate INV-YYYYMMDD-#### scoped per day. */
  private async nextInvoiceNumber(prefix = 'INV'): Promise<string> {
    const now = new Date();
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);
    const count = await this.prisma.order.count({ where: { createdAt: { gte: start, lt: end } } });
    const datePart = `${start.getFullYear()}${String(start.getMonth() + 1).padStart(2, '0')}${String(start.getDate()).padStart(2, '0')}`;
    return `${prefix}-${datePart}-${String(count + 1).padStart(4, '0')}`;
  }

  /**
   * Create an order. All monetary calculation happens here (server-side
   * authoritative). Tax is resolved per product (override → global) and
   * snapshotted into each order item.
   */
  async create(dto: CreateOrderDto, cashierId: string) {
    const productIds = dto.items.map((i) => i.productId);
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds }, deletedAt: null, isActive: true },
    });
    const map = new Map(products.map((p) => [p.id, p]));

    const missing = productIds.filter((id) => !map.has(id));
    if (missing.length) throw new BadRequestException(`Unavailable products: ${missing.join(', ')}`);

    const globalTax = (await this.tax.getGlobalTax()).percentage as Prisma.Decimal;

    const itemRows = dto.items.map((item) => {
      const product = map.get(item.productId)!;
      const rate = this.tax.resolveRate(product.taxPercentage, globalTax);
      const { lineSubtotal, taxAmount, lineTotal } = computeLine({
        price: product.price,
        quantity: item.quantity,
        taxPercentage: rate,
      });
      return {
        productId: product.id,
        productName: product.name,
        price: product.price,
        quantity: item.quantity,
        taxPercentage: rate,
        taxAmount,
        lineTotal,
        _lineSubtotal: lineSubtotal,
      };
    });

    const totals = computeOrderTotals(
      itemRows.map((r) => ({ lineSubtotal: r._lineSubtotal, taxAmount: r.taxAmount })),
    );
    const invoiceNumber = await this.nextInvoiceNumber(process.env.INVOICE_PREFIX || 'INV');

    return this.prisma.order.create({
      data: {
        invoiceNumber,
        cashierId,
        subtotal: totals.subtotal,
        taxAmount: totals.taxAmount,
        grandTotal: totals.grandTotal,
        status: 'PENDING',
        items: {
          create: itemRows.map(({ _lineSubtotal, ...row }) => row),
        },
      },
      include: { items: true, payments: true, cashier: { select: { username: true } } },
    });
  }

  async findAll(q: OrderQueryDto) {
    const where: Prisma.OrderWhereInput = {
      ...(q.search ? { invoiceNumber: { contains: q.search, mode: 'insensitive' } } : {}),
      ...(q.from || q.to
        ? { createdAt: { ...(q.from ? { gte: new Date(q.from) } : {}), ...(q.to ? { lte: new Date(q.to) } : {}) } }
        : {}),
    };
    const [data, total] = await this.prisma.$transaction([
      this.prisma.order.findMany({
        where,
        skip: q.skip,
        take: q.limit,
        orderBy: { createdAt: 'desc' },
        include: { cashier: { select: { username: true } } },
      }),
      this.prisma.order.count({ where }),
    ]);
    return { data, meta: buildMeta(total, q.page, q.limit) };
  }

  async findOne(id: string) {
    const order = await this.prisma.order.findUnique({
      where: { id },
      include: { items: true, payments: true, cashier: { select: { username: true } } },
    });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }
}
