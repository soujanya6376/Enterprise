import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Platform } from '@prisma/client';

export class ThemeEntity {
  @ApiProperty() id: string;
  @ApiProperty() name: string;
  @ApiPropertyOptional() description?: string | null;
  @ApiProperty({ description: 'Bumped on every token change; used as the ETag' })
  revision: number;
  @ApiProperty() schemaVersion: number;
  @ApiProperty({ type: 'object', additionalProperties: true })
  tokens: Record<string, unknown>;
  @ApiProperty() updatedAt: Date;
}

export class ThemeSummaryEntity {
  @ApiProperty() id: string;
  @ApiProperty() name: string;
  @ApiPropertyOptional() description?: string | null;
  @ApiProperty() revision: number;
  @ApiProperty({ enum: Platform, isArray: true, description: 'Platforms this theme is live on' })
  platforms: Platform[];
  @ApiProperty() updatedAt: Date;
}

export class ThemeAssignmentEntity {
  @ApiProperty({ enum: Platform }) platform: Platform;
  @ApiProperty() themeId: string;
  @ApiProperty() themeName: string;
  @ApiProperty() updatedAt: Date;
}
