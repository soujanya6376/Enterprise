import { Body, Controller, Get, Param, Patch, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { TaxService } from './tax.service';
import { SetGlobalTaxDto, SetProductTaxDto } from './dto/tax.dto';
import { Roles } from '../../common/decorators/roles.decorator';

@ApiTags('tax')
@ApiBearerAuth()
@Controller('tax')
export class TaxController {
  constructor(private readonly tax: TaxService) {}

  @Get('global')
  @ApiOperation({ summary: 'Get active global tax' })
  getGlobal() {
    return this.tax.getGlobalTax();
  }

  @Roles('ADMIN')
  @Put('global')
  @ApiOperation({ summary: 'Set global tax percentage' })
  setGlobal(@Body() dto: SetGlobalTaxDto) {
    return this.tax.setGlobalTax(dto.percentage);
  }

  @Roles('ADMIN')
  @Patch('products/:id')
  @ApiOperation({ summary: 'Set or clear a product tax override' })
  setProduct(@Param('id') id: string, @Body() dto: SetProductTaxDto) {
    return this.tax.setProductTax(id, dto.taxPercentage);
  }
}
