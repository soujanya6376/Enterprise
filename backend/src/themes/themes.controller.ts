import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  NotFoundException,
  Param,
  ParseEnumPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
  Query,
  Req,
  Res,
} from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { Platform } from '@prisma/client';
import type { Request, Response } from 'express';

import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Public } from '../common/decorators/public.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { PaginationDto } from '../common/dto/pagination.dto';
import { ActiveThemeQueryDto } from './dto/active-theme-query.dto';
import { AssignThemeDto } from './dto/assign-theme.dto';
import { CreateThemeDto } from './dto/create-theme.dto';
import { DuplicateThemeDto } from './dto/duplicate-theme.dto';
import { UpdateThemeDto } from './dto/update-theme.dto';
import { ThemesService } from './themes.service';

@ApiTags('themes')
@Controller('themes')
export class ThemesController {
  constructor(private readonly themes: ThemesService) {}

  // Declared before ':id' so "active" isn't swallowed by the UUID route.
  @Get('active')
  @Public()
  @ApiOperation({ summary: 'Token payload this platform should boot with' })
  async active(
    @Query() query: ActiveThemeQueryDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const theme = await this.themes.findActiveForPlatform(query.platform);
    if (!theme) {
      throw new NotFoundException(`No theme assigned to ${query.platform}`);
    }

    if (req.headers['if-none-match'] === theme.etag) {
      res.status(HttpStatus.NOT_MODIFIED);
      return;
    }

    res.setHeader('ETag', theme.etag);
    res.setHeader('Cache-Control', 'no-cache');
    return { theme };
  }

  @Get('assignments')
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Current theme for each platform' })
  listAssignments() {
    return this.themes.listAssignments();
  }

  @Put('assignments/:platform')
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Make a theme live on a platform' })
  assign(
    @Param('platform', new ParseEnumPipe(Platform)) platform: Platform,
    @Body() dto: AssignThemeDto,
    @CurrentUser('userId') userId: string,
  ) {
    return this.themes.assign(platform, dto, userId);
  }

  @Get()
  @Roles('ADMIN')
  @ApiOperation({ summary: 'List themes (metadata only)' })
  list(@Query() pagination: PaginationDto) {
    return this.themes.list(pagination);
  }

  @Post()
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Create a theme' })
  create(@Body() dto: CreateThemeDto, @CurrentUser('userId') userId: string) {
    return this.themes.create(dto, userId);
  }

  @Get(':id')
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Get a theme with its full token payload' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.themes.findOne(id);
  }

  @Patch(':id')
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Update a theme; token changes bump the revision' })
  update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateThemeDto) {
    return this.themes.update(id, dto);
  }

  @Post(':id/duplicate')
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Copy a theme so a live one can be edited safely' })
  duplicate(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: DuplicateThemeDto,
    @CurrentUser('userId') userId: string,
  ) {
    return this.themes.duplicate(id, dto, userId);
  }

  @Delete(':id')
  @Roles('ADMIN')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Soft delete a theme (409 if live on any platform)' })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.themes.remove(id);
  }
}
