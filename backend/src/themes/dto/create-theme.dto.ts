import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsObject, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateThemeDto {
  @ApiProperty({ example: 'Midnight' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(60)
  name: string;

  @ApiPropertyOptional({ example: 'High-contrast dark theme for evening shifts' })
  @IsOptional()
  @IsString()
  @MaxLength(280)
  description?: string;

  @ApiProperty({
    description:
      'Full token payload — { schemaVersion, modes: { light, dark } }. Validated against the v1 schema; see docs/THEMING.md.',
    type: 'object',
    additionalProperties: true,
  })
  @IsObject()
  tokens: Record<string, unknown>;
}
