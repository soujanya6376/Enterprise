import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OrdersService } from '../orders/orders.service';

@Injectable()
export class InvoiceService {
  constructor(private orders: OrdersService, private config: ConfigService) {}

  private store() {
    return {
      name: this.config.get('STORE_NAME', 'My Store'),
      address: this.config.get('STORE_ADDRESS', ''),
      phone: this.config.get('STORE_PHONE', ''),
    };
  }

  private money(v: any) {
    return Number(v).toFixed(2);
  }

  private async data(orderId: string) {
    const order = await this.orders.findOne(orderId);
    const paid = order.payments
      .filter((p) => p.status !== 'REFUNDED')
      .reduce((s, p) => s + Number(p.amount), 0);
    const method = order.payments.length ? order.payments[order.payments.length - 1].paymentMethod : '—';
    return { order, store: this.store(), paid, method };
  }

  /** 80mm thermal-friendly HTML. */
  async thermalHtml(orderId: string): Promise<string> {
    const { order, store, method } = await this.data(orderId);
    const rows = order.items
      .map(
        (i) => `
      <tr>
        <td class="l">${i.productName}<br><span class="dim">${i.quantity} x ${this.money(i.price)} (${this.money(i.taxPercentage)}%)</span></td>
        <td class="r">${this.money(i.lineTotal)}</td>
      </tr>`,
      )
      .join('');

    return `<!doctype html><html><head><meta charset="utf-8">
<title>${order.invoiceNumber}</title>
<style>
  @page { size: 80mm auto; margin: 0; }
  * { box-sizing: border-box; }
  body { width: 80mm; margin: 0; padding: 6px 8px; font-family: 'Courier New', monospace; font-size: 12px; color: #000; }
  h1 { font-size: 15px; text-align: center; margin: 2px 0; }
  .center { text-align: center; }
  .dim { color: #444; font-size: 10px; }
  table { width: 100%; border-collapse: collapse; }
  td { padding: 2px 0; vertical-align: top; }
  .l { text-align: left; } .r { text-align: right; }
  .line { border-top: 1px dashed #000; margin: 6px 0; }
  .totals td { font-size: 12px; }
  .grand { font-weight: bold; font-size: 14px; }
  .thanks { text-align: center; margin-top: 8px; }
  @media print { button { display: none; } }
</style></head>
<body onload="window.print && window.print()">
  <h1>${store.name}</h1>
  <div class="center dim">${store.address}</div>
  <div class="center dim">${store.phone}</div>
  <div class="line"></div>
  <div>Invoice: ${order.invoiceNumber}</div>
  <div>Date: ${new Date(order.createdAt).toLocaleString()}</div>
  <div>Cashier: ${order.cashier?.username ?? ''}</div>
  <div class="line"></div>
  <table>${rows}</table>
  <div class="line"></div>
  <table class="totals">
    <tr><td class="l">Subtotal</td><td class="r">${this.money(order.subtotal)}</td></tr>
    <tr><td class="l">Tax</td><td class="r">${this.money(order.taxAmount)}</td></tr>
    <tr class="grand"><td class="l">Grand Total</td><td class="r">${this.money(order.grandTotal)}</td></tr>
  </table>
  <div class="line"></div>
  <div>Payment: ${method}</div>
  <div>Status: ${order.status}</div>
  <div class="thanks">*** Thank you! Visit again ***</div>
</body></html>`;
  }

  /** A4 invoice HTML (used by PDF renderer). */
  async a4Html(orderId: string): Promise<string> {
    const { order, store, method } = await this.data(orderId);
    const rows = order.items
      .map(
        (i, idx) => `
      <tr>
        <td>${idx + 1}</td>
        <td>${i.productName}</td>
        <td class="r">${i.quantity}</td>
        <td class="r">${this.money(i.price)}</td>
        <td class="r">${this.money(i.taxPercentage)}%</td>
        <td class="r">${this.money(i.lineTotal)}</td>
      </tr>`,
      )
      .join('');

    return `<!doctype html><html><head><meta charset="utf-8">
<title>${order.invoiceNumber}</title>
<style>
  @page { size: A4; margin: 18mm; }
  body { font-family: Arial, Helvetica, sans-serif; color: #1a1a1a; font-size: 13px; }
  .head { display: flex; justify-content: space-between; align-items: flex-start; }
  .store h1 { margin: 0; font-size: 22px; }
  .muted { color: #666; }
  .inv { text-align: right; }
  table { width: 100%; border-collapse: collapse; margin-top: 24px; }
  th, td { padding: 8px 10px; border-bottom: 1px solid #e2e2e2; }
  th { background: #f4f4f5; text-align: left; font-size: 12px; text-transform: uppercase; letter-spacing: .03em; }
  .r { text-align: right; }
  .totals { width: 280px; margin-left: auto; margin-top: 16px; }
  .totals td { border: none; padding: 4px 10px; }
  .grand td { font-weight: bold; font-size: 16px; border-top: 2px solid #1a1a1a; }
  .foot { margin-top: 40px; text-align: center; color: #666; }
</style></head>
<body>
  <div class="head">
    <div class="store">
      <h1>${store.name}</h1>
      <div class="muted">${store.address}</div>
      <div class="muted">${store.phone}</div>
    </div>
    <div class="inv">
      <h2>INVOICE</h2>
      <div><strong>${order.invoiceNumber}</strong></div>
      <div class="muted">${new Date(order.createdAt).toLocaleString()}</div>
      <div class="muted">Cashier: ${order.cashier?.username ?? ''}</div>
    </div>
  </div>
  <table>
    <thead><tr><th>#</th><th>Item</th><th class="r">Qty</th><th class="r">Rate</th><th class="r">Tax</th><th class="r">Amount</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>
  <table class="totals">
    <tr><td>Subtotal</td><td class="r">${this.money(order.subtotal)}</td></tr>
    <tr><td>Tax</td><td class="r">${this.money(order.taxAmount)}</td></tr>
    <tr class="grand"><td>Grand Total</td><td class="r">${this.money(order.grandTotal)}</td></tr>
  </table>
  <div style="margin-top:16px">Payment Method: <strong>${method}</strong> &nbsp;|&nbsp; Status: <strong>${order.status}</strong></div>
  <div class="foot">Thank you for your business!</div>
</body></html>`;
  }

  /** Render the A4 HTML to a PDF buffer via Puppeteer. */
  async pdf(orderId: string): Promise<Buffer> {
    const html = await this.a4Html(orderId);
    // Lazy import keeps startup fast and avoids hard dependency at boot.
    const puppeteer = await import('puppeteer');
    const browser = await puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
      ...(process.env.PUPPETEER_EXECUTABLE_PATH ? { executablePath: process.env.PUPPETEER_EXECUTABLE_PATH } : {}),
    });
    try {
      const page = await browser.newPage();
      await page.setContent(html, { waitUntil: 'networkidle0' });
      const pdf = await page.pdf({ format: 'A4', printBackground: true });
      return Buffer.from(pdf);
    } finally {
      await browser.close();
    }
  }
}
