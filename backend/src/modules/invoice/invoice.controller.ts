import { Controller, Get, Param, Res } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { InvoiceService } from './invoice.service';

@ApiTags('invoice')
@ApiBearerAuth()
@Controller('invoice')
export class InvoiceController {
  constructor(private readonly invoice: InvoiceService) {}

  @Get(':orderId/thermal')
  @ApiOperation({ summary: 'Printer-friendly 80mm thermal receipt (HTML)' })
  async thermal(@Param('orderId') orderId: string, @Res() res: Response) {
    const html = await this.invoice.thermalHtml(orderId);
    res.set({ 'Content-Type': 'text/html; charset=utf-8' });
    res.send(html);
  }

  @Get(':orderId/pdf')
  @ApiOperation({ summary: 'Downloadable A4 PDF invoice' })
  async pdf(@Param('orderId') orderId: string, @Res() res: Response) {
    const buf = await this.invoice.pdf(orderId);
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="invoice-${orderId}.pdf"`,
    });
    res.send(buf);
  }
}
