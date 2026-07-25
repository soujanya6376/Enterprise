import { Injectable } from '@nestjs/common';
import { Prisma, OrderStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

const COUNTED: OrderStatus[] = [OrderStatus.PAID, OrderStatus.PARTIALLY_PAID];

@Injectable()
export class ReportsService {
  constructor(private prisma: PrismaService) {}

  private startOfDay(d = new Date()) {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate());
  }
  private startOfMonth(d = new Date()) {
    return new Date(d.getFullYear(), d.getMonth(), 1);
  }

  private async aggregate(from: Date) {
    const result = await this.prisma.order.aggregate({
      where: { createdAt: { gte: from }, status: { in: COUNTED } },
      _sum: { grandTotal: true, taxAmount: true },
      _count: { _all: true },
    });
    return {
      orders: result._count._all,
      revenue: Number(result._sum.grandTotal ?? 0),
      taxCollected: Number(result._sum.taxAmount ?? 0),
    };
  }

  async dashboard() {
    const today = await this.aggregate(this.startOfDay());
    const month = await this.aggregate(this.startOfMonth());
    return {
      today: { ordersCount: today.orders, revenue: today.revenue, taxCollected: today.taxCollected },
      monthly: { revenue: month.revenue, taxCollected: month.taxCollected },
    };
  }

  async topProducts(limit = 10) {
    const grouped = await this.prisma.orderItem.groupBy({
      by: ['productId', 'productName'],
      _sum: { quantity: true, lineTotal: true },
      orderBy: { _sum: { quantity: 'desc' } },
      take: limit,
    });
    return grouped.map((g) => ({
      productId: g.productId,
      productName: g.productName,
      quantitySold: g._sum.quantity ?? 0,
      revenue: Number(g._sum.lineTotal ?? 0),
    }));
  }

  async recentOrders(limit = 10) {
    return this.prisma.order.findMany({
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: { cashier: { select: { username: true } } },
    });
  }
}
