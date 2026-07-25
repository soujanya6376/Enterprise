import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class TaxService {
  constructor(private prisma: PrismaService) {}

  async getGlobalTax() {
    const tax = await this.prisma.globalTaxSetting.findFirst({
      where: { isActive: true },
      orderBy: { updatedAt: 'desc' },
    });
    return tax ?? { percentage: new Prisma.Decimal(0), isActive: true };
  }

  /** Replace the active global tax setting. */
  async setGlobalTax(percentage: number) {
    await this.prisma.globalTaxSetting.updateMany({ where: { isActive: true }, data: { isActive: false } });
    return this.prisma.globalTaxSetting.create({
      data: { percentage: new Prisma.Decimal(percentage), isActive: true },
    });
  }

  async setProductTax(productId: string, taxPercentage: number | null) {
    const product = await this.prisma.product.findFirst({ where: { id: productId, deletedAt: null } });
    if (!product) throw new NotFoundException('Product not found');
    return this.prisma.product.update({
      where: { id: productId },
      data: { taxPercentage: taxPercentage === null ? null : new Prisma.Decimal(taxPercentage) },
    });
  }

  /**
   * Tax resolution: product override takes priority, else global tax.
   */
  resolveRate(productTax: Prisma.Decimal | null | undefined, globalTax: Prisma.Decimal): Prisma.Decimal {
    return productTax !== null && productTax !== undefined ? productTax : globalTax;
  }
}
