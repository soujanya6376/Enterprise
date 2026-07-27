import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsUUID } from 'class-validator';

export class AssignThemeDto {
  @ApiProperty({ description: 'Theme to make live on this platform' })
  @IsUUID()
  @IsNotEmpty()
  themeId: string;
}
