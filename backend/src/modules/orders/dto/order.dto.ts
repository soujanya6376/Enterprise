import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMinSize, IsArray, IsInt, IsOptional, IsString, IsUUID, Min, ValidateNested } from 'class-validator';
import { PaginationDto } from '../../../common/dto/pagination.dto';

export class CartItemDto {
  @ApiProperty()
  @IsUUID()
  productId: string;

  @ApiProperty({ example: 2, minimum: 1 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  quantity: number;
}

export class CreateOrderDto {
  @ApiProperty({ type: [CartItemDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CartItemDto)
  items: CartItemDto[];
}

export class OrderQueryDto extends PaginationDto {
  @ApiPropertyOptional({ description: 'ISO date (orders on/after)' })
  @IsOptional()
  @IsString()
  from?: string;

  @ApiPropertyOptional({ description: 'ISO date (orders on/before)' })
  @IsOptional()
  @IsString()
  to?: string;
}
