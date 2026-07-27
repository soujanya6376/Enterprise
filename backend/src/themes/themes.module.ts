import { Module } from '@nestjs/common';

import { PrismaModule } from '../prisma/prisma.module';
import { ThemesController } from './themes.controller';
import { ThemesRepository } from './themes.repository';
import { ThemesService } from './themes.service';

@Module({
  imports: [PrismaModule],
  controllers: [ThemesController],
  providers: [ThemesService, ThemesRepository],
  exports: [ThemesService],
})
export class ThemesModule {}
