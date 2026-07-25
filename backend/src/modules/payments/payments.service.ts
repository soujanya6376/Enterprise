import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, PaymentStatus, OrderStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { round2 } from '../../common/utils/money.util';
import { CreatePaymentDto } from './dto/payment.dto';

@Injectable()
export class PaymentsService {
  constructor(private prisma: PrismaService) {}

  /** Record a payment and recompute order status from total paid. */
  async create(dto: CreatePaymentDto) {
    return this.prisma.$transaction(async (tx) => {
      const order = await tx.order.findUnique({ where: { id: dto.orderId }, include: { payments: true } });
      if (!order) throw new NotFoundException('Order not found');
      if (order.status === 'REFUNDED') throw new BadRequestException('Order is refunded');

      const alreadyPaid = order.payments
        .filter((p) => p.status !== PaymentStatus.REFUNDED)
        .reduce((sum, p) => sum.add(p.amount), new Prisma.Decimal(0));
      const newPaid = round2(alreadyPaid.add(dto.amount));
      const grand = order.grandTotal as Prisma.Decimal;

      if (newPaid.greaterThan(grand)) {
        throw new BadRequestException(`Payment exceeds balance due (${grand.sub(alreadyPaid).toFixed(2)})`);
      }

      let orderStatus: OrderStatus;
      let paymentStatus: PaymentStatus;
      if (newPaid.greaterThanOrEqualTo(grand)) {
        orderStatus = OrderStatus.PAID;
        paymentStatus = PaymentStatus.PAID;
      } else {
        orderStatus = OrderStatus.PARTIALLY_PAID;
        paymentStatus = PaymentStatus.PARTIALLY_PAID;
      }

      const payment = await tx.payment.create({
        data: {
          orderId: dto.orderId,
          amount: new Prisma.Decimal(dto.amount),
          paymentMethod: dto.paymentMethod,
          status: paymentStatus,
        },
      });
      await tx.order.update({ where: { id: dto.orderId }, data: { status: orderStatus } });
      return { payment, order: { id: order.id, status: orderStatus, paid: newPaid.toFixed(2), grandTotal: grand.toFixed(2) } };
    });
  }

  findByOrder(orderId: string) {
    return this.prisma.payment.findMany({ where: { orderId }, orderBy: { createdAt: 'asc' } });
  }

  async refund(paymentId: string) {
    const payment = await this.prisma.payment.findUnique({ where: { id: paymentId } });
    if (!payment) throw new NotFoundException('Payment not found');
    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.payment.update({ where: { id: paymentId }, data: { status: PaymentStatus.REFUNDED } });
      await tx.order.update({ where: { id: payment.orderId }, data: { status: OrderStatus.REFUNDED } });
      return updated;
    });
  }
}
