import { Module } from '@nestjs/common';
import { ProductsService } from './products.service';
import { ProductsController } from './products.controller';
import { ProductImportService } from './product-import.service';

@Module({
  controllers: [ProductsController],
  providers: [ProductsService, ProductImportService],
  exports: [ProductsService],
})
export class ProductsModule {}
