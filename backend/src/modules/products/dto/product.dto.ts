import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';
import { PaginationDto } from '../../../common/dto/pagination.dto';

export class CreateProductDto {
  @ApiProperty({ example: 'Coffee' })
  @IsString()
  @MaxLength(200)
  name: string;

  @ApiPropertyOptional({ example: 'Hot Coffee' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 100 })
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  price: number;

  @ApiPropertyOptional({ example: 5, description: 'null/omitted => use global tax' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  taxPercentage?: number;
}

export class UpdateProductDto extends PartialType(CreateProductDto) {}

export class UpdateStatusDto {
  @ApiProperty()
  @IsBoolean()
  isActive: boolean;
}

export class ProductQueryDto extends PaginationDto {
  @ApiPropertyOptional({ description: 'Filter by active state' })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  isActive?: boolean;
}
