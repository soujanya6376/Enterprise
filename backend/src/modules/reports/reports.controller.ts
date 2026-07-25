import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { ReportsService } from './reports.service';
import { Roles } from '../../common/decorators/roles.decorator';

@ApiTags('reports')
@ApiBearerAuth()
@Roles('ADMIN')
@Controller('reports')
export class ReportsController {
  constructor(private readonly reports: ReportsService) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Today + monthly revenue and tax' })
  dashboard() {
    return this.reports.dashboard();
  }

  @Get('top-products')
  @ApiOperation({ summary: 'Top selling products' })
  topProducts(@Query('limit') limit?: string) {
    return this.reports.topProducts(limit ? Number(limit) : 10);
  }

  @Get('recent-orders')
  @ApiOperation({ summary: 'Recent orders' })
  recentOrders(@Query('limit') limit?: string) {
    return this.reports.recentOrders(limit ? Number(limit) : 10);
  }
}
