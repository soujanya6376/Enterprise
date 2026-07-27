import { ApiProperty } from '@nestjs/swagger';
import { Platform } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class ActiveThemeQueryDto {
  @ApiProperty({ enum: Platform, example: Platform.WEB })
  @IsEnum(Platform)
  platform: Platform;
}
