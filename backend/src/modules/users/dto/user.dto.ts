import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { IsBoolean, IsEmail, IsIn, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateUserDto {
  @ApiProperty()
  @IsString()
  @MinLength(3)
  username: string;

  @ApiProperty()
  @IsEmail()
  email: string;

  @ApiProperty()
  @IsString()
  @MinLength(6)
  password: string;

  @ApiProperty({ enum: ['ADMIN', 'USER'], default: 'USER' })
  @IsIn(['ADMIN', 'USER'])
  roleName: 'ADMIN' | 'USER';
}

export class UpdateUserDto extends PartialType(CreateUserDto) {
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class ResetPasswordDto {
  @ApiProperty()
  @IsString()
  @MinLength(6)
  newPassword: string;
}
