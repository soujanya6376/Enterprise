import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { InvoiceService } from './invoice.service';
import { InvoiceController } from './invoice.controller';
import { OrdersModule } from '../orders/orders.module';

@Module({
  imports: [ConfigModule, OrdersModule],
  controllers: [InvoiceController],
  providers: [InvoiceService],
})
export class InvoiceModule {}
