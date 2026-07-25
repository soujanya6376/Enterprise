import { Prisma } from '@prisma/client';

type Num = Prisma.Decimal | number | string;

const D = (v: Num) => new Prisma.Decimal(v);

/** Round half-up to 2 decimal places. */
export function round2(value: Num): Prisma.Decimal {
  return D(value).toDecimalPlaces(2, Prisma.Decimal.ROUND_HALF_UP);
}

export interface LineInput {
  price: Num;
  quantity: number;
  taxPercentage: Num;
}

export interface LineResult {
  lineSubtotal: Prisma.Decimal;
  taxAmount: Prisma.Decimal;
  lineTotal: Prisma.Decimal;
}

/** Compute a single cart line. */
export function computeLine({ price, quantity, taxPercentage }: LineInput): LineResult {
  const lineSubtotal = round2(D(price).mul(quantity));
  const taxAmount = round2(lineSubtotal.mul(D(taxPercentage)).div(100));
  const lineTotal = round2(lineSubtotal.add(taxAmount));
  return { lineSubtotal, taxAmount, lineTotal };
}

export interface OrderTotals {
  subtotal: Prisma.Decimal;
  taxAmount: Prisma.Decimal;
  grandTotal: Prisma.Decimal;
}

/** Aggregate line results into order totals. */
export function computeOrderTotals(
  lines: { lineSubtotal: Num; taxAmount: Num }[],
): OrderTotals {
  let subtotal = D(0);
  let taxAmount = D(0);
  for (const l of lines) {
    subtotal = subtotal.add(D(l.lineSubtotal));
    taxAmount = taxAmount.add(D(l.taxAmount));
  }
  subtotal = round2(subtotal);
  taxAmount = round2(taxAmount);
  return { subtotal, taxAmount, grandTotal: round2(subtotal.add(taxAmount)) };
}
