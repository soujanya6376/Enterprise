import { computeLine, computeOrderTotals, round2 } from './money.util';

describe('money.util', () => {
  it('rounds half-up to 2dp', () => {
    expect(round2('1.005').toFixed(2)).toBe('1.01');
    expect(round2(2.344).toFixed(2)).toBe('2.34');
  });

  it('computes a line (price 100 x 2 @ 5%)', () => {
    const r = computeLine({ price: '100', quantity: 2, taxPercentage: '5' });
    expect(r.lineSubtotal.toFixed(2)).toBe('200.00');
    expect(r.taxAmount.toFixed(2)).toBe('10.00');
    expect(r.lineTotal.toFixed(2)).toBe('210.00');
  });

  it('matches the spec cart item example', () => {
    // productId Coffee, price 100, qty 2, tax 5% => taxAmount 10, lineTotal 210
    const r = computeLine({ price: 100, quantity: 2, taxPercentage: 5 });
    expect(Number(r.taxAmount)).toBe(10);
    expect(Number(r.lineTotal)).toBe(210);
  });

  it('aggregates order totals', () => {
    const a = computeLine({ price: 100, quantity: 2, taxPercentage: 5 }); // 200 + 10
    const b = computeLine({ price: 250, quantity: 1, taxPercentage: 18 }); // 250 + 45
    const totals = computeOrderTotals([
      { lineSubtotal: a.lineSubtotal, taxAmount: a.taxAmount },
      { lineSubtotal: b.lineSubtotal, taxAmount: b.taxAmount },
    ]);
    expect(totals.subtotal.toFixed(2)).toBe('450.00');
    expect(totals.taxAmount.toFixed(2)).toBe('55.00');
    expect(totals.grandTotal.toFixed(2)).toBe('505.00');
  });
});
