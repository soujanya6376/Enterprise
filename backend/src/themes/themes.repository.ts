import { Injectable } from '@nestjs/common';
import { Platform, Prisma, Theme } from '@prisma/client';

import { PaginationDto } from '../common/dto/pagination.dto';
import { paginate } from '../common/helpers/paginate';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Data access only — no business rules. Every read filters out soft-deleted
 * themes so callers can't accidentally resurrect one.
 */
@Injectable()
export class ThemesRepository {
  constructor(private readonly prisma: PrismaService) {}

  private readonly notDeleted = { deletedAt: null };

  async paginate(pagination: PaginationDto) {
    const { search } = pagination;
    const where: Prisma.ThemeWhereInput = {
      ...this.notDeleted,
      ...(search
        ? {
            OR: [
              { name: { contains: search, mode: 'insensitive' as const } },
              { description: { contains: search, mode: 'insensitive' as const } },
            ],
          }
        : {}),
    };

    return paginate(this.prisma.theme, {
      where,
      orderBy: { name: 'asc' },
      // The list screen only needs metadata; token payloads are several KB each
      // and would bloat the response for no reason.
      select: {
        id: true,
        name: true,
        description: true,
        revision: true,
        schemaVersion: true,
        updatedAt: true,
        assignments: { select: { platform: true } },
      },
      pagination,
    });
  }

  findById(id: string): Promise<Theme | null> {
    return this.prisma.theme.findFirst({ where: { id, ...this.notDeleted } });
  }

  findByName(name: string): Promise<Theme | null> {
    return this.prisma.theme.findFirst({ where: { name, ...this.notDeleted } });
  }

  create(data: Prisma.ThemeCreateInput): Promise<Theme> {
    return this.prisma.theme.create({ data });
  }

  update(id: string, data: Prisma.ThemeUpdateInput): Promise<Theme> {
    return this.prisma.theme.update({ where: { id }, data });
  }

  softDelete(id: string): Promise<Theme> {
    return this.prisma.theme.update({
      where: { id },
      data: { deletedAt: new Date(), isActive: false },
    });
  }

  async findPlatformsUsingTheme(themeId: string): Promise<Platform[]> {
    const rows = await this.prisma.themeAssignment.findMany({
      where: { themeId },
      select: { platform: true },
    });
    return rows.map((r) => r.platform);
  }

  findAllAssignments() {
    return this.prisma.themeAssignment.findMany({
      include: {
        theme: { select: { id: true, name: true, revision: true } },
      },
      orderBy: { platform: 'asc' },
    });
  }

  findAssignment(platform: Platform) {
    return this.prisma.themeAssignment.findUnique({
      where: { platform },
      include: { theme: true },
    });
  }

  upsertAssignment(platform: Platform, themeId: string, userId: string) {
    return this.prisma.themeAssignment.upsert({
      where: { platform },
      create: { platform, themeId, updatedById: userId },
      update: { themeId, updatedById: userId },
      include: { theme: { select: { id: true, name: true, revision: true } } },
    });
  }
}
