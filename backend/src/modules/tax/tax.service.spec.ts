import { Prisma } from '@prisma/client';
import { TaxService } from './tax.service';

describe('TaxService.resolveRate', () => {
  const svc = new TaxService({} as any);
  const global = new Prisma.Decimal(18);

  it('uses product tax when set', () => {
    expect(svc.resolveRate(new Prisma.Decimal(5), global).toString()).toBe('5');
  });

  it('falls back to global when product tax is null', () => {
    expect(svc.resolveRate(null, global).toString()).toBe('18');
  });

  it('falls back to global when product tax is undefined', () => {
    expect(svc.resolveRate(undefined, global).toString()).toBe('18');
  });

  it('treats product tax of 0 as a valid override (not fallback)', () => {
    expect(svc.resolveRate(new Prisma.Decimal(0), global).toString()).toBe('0');
  });
});
