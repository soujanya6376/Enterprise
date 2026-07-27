import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class DuplicateThemeDto {
  @ApiProperty({ example: 'Midnight (draft)' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(60)
  name: string;
}
