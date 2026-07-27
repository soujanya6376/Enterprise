import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsObject, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateThemeDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(60)
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(280)
  description?: string;

  @ApiPropertyOptional({
    description: 'Replaces the whole token payload. Bumps the theme revision.',
    type: 'object',
    additionalProperties: true,
  })
  @IsOptional()
  @IsObject()
  tokens?: Record<string, unknown>;
}
