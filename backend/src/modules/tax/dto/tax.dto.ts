import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsNumber, IsOptional, Max, Min, ValidateIf } from 'class-validator';

export class SetGlobalTaxDto {
  @ApiProperty({ example: 18 })
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(100)
  percentage: number;
}

export class SetProductTaxDto {
  @ApiPropertyOptional({ example: 5, description: 'null clears override (use global)' })
  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(100)
  taxPercentage: number | null;
}
