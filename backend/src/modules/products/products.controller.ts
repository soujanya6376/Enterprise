import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Res,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { ProductsService } from './products.service';
import type { ImportSummary } from './product-import.service';
import { CreateProductDto, ProductQueryDto, UpdateProductDto, UpdateStatusDto } from './dto/product.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('products')
@ApiBearerAuth()
@Controller('products')
export class ProductsController {
  constructor(private readonly products: ProductsService) {}

  @Get()
  @ApiOperation({ summary: 'List products (search, filter, paginate)' })
  findAll(@Query() q: ProductQueryDto) {
    return this.products.findAll(q);
  }

  // static routes before :id
  @Roles('ADMIN')
  @Get('import/template')
  @ApiOperation({ summary: 'Download Excel import template' })
  async template(@Res() res: Response) {
    const buf = await this.products.importTemplate();
    res.set({
      'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'Content-Disposition': 'attachment; filename="product-import-template.xlsx"',
    });
    res.send(buf);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.products.findOne(id);
  }

  @Roles('ADMIN')
  @Post()
  @ApiOperation({ summary: 'Create product' })
  create(@Body() dto: CreateProductDto) {
    return this.products.create(dto);
  }

  @Roles('ADMIN')
  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateProductDto) {
    return this.products.update(id, dto);
  }

  @Roles('ADMIN')
  @Patch(':id/status')
  @ApiOperation({ summary: 'Activate / deactivate product' })
  setStatus(@Param('id') id: string, @Body() dto: UpdateStatusDto) {
    return this.products.setStatus(id, dto.isActive);
  }

  @Roles('ADMIN')
  @Delete(':id')
  @ApiOperation({ summary: 'Soft-delete product' })
  remove(@Param('id') id: string) {
    return this.products.remove(id);
  }

  @Roles('ADMIN')
  @Post(':id/image')
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'object', properties: { file: { type: 'string', format: 'binary' } } } })
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 5 * 1024 * 1024 } }))
  uploadImage(@Param('id') id: string, @UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('Image file required');
    if (!file.mimetype.startsWith('image/')) throw new BadRequestException('File must be an image');
    return this.products.setImage(id, file);
  }

  @Roles('ADMIN')
  @Post('import')
  @ApiOperation({ summary: 'Bulk import products from .xlsx' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'object', properties: { file: { type: 'string', format: 'binary' } } } })
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 10 * 1024 * 1024 } }))
  import(@UploadedFile() file: Express.Multer.File, @CurrentUser('userId') userId: string): Promise<ImportSummary> {
    if (!file) throw new BadRequestException('Excel file required');
    return this.products.importExcel(file, userId);
  }
}
