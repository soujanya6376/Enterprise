import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsEnum, IsNumber, IsUUID, Min } from 'class-validator';
import { PaymentMethod } from '@prisma/client';

export class CreatePaymentDto {
  @ApiProperty()
  @IsUUID()
  orderId: string;

  @ApiProperty({ example: 210 })
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  amount: number;

  @ApiProperty({ enum: PaymentMethod })
  @IsEnum(PaymentMethod)
  paymentMethod: PaymentMethod;
}
