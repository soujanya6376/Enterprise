import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Platform, Prisma, Theme } from '@prisma/client';

import { PaginationDto } from '../common/dto/pagination.dto';
import { AssignThemeDto } from './dto/assign-theme.dto';
import { CreateThemeDto } from './dto/create-theme.dto';
import { DuplicateThemeDto } from './dto/duplicate-theme.dto';
import { UpdateThemeDto } from './dto/update-theme.dto';
import { ThemesRepository } from './themes.repository';
import {
  SCHEMA_VERSION,
  TokenValidationError,
  validateTokenPayload,
} from './theme-tokens.schema';

@Injectable()
export class ThemesService {
  constructor(private readonly repo: ThemesRepository) {}

  // --- CRUD -----------------------------------------------------------------

  async list(pagination: PaginationDto) {
    return this.repo.paginate(pagination);
  }

  async findOne(id: string): Promise<Theme> {
    const theme = await this.repo.findById(id);
    if (!theme) throw new NotFoundException(`Theme ${id} not found`);
    return theme;
  }

  async create(dto: CreateThemeDto, userId: string): Promise<Theme> {
    this.assertValidTokens(dto.tokens);
    await this.assertNameAvailable(dto.name);

    return this.repo.create({
      name: dto.name,
      description: dto.description,
      tokens: dto.tokens as Prisma.InputJsonValue,
      schemaVersion: SCHEMA_VERSION,
      revision: 1,
      createdBy: { connect: { id: userId } },
    });
  }

  async update(id: string, dto: UpdateThemeDto): Promise<Theme> {
    const existing = await this.findOne(id);

    if (dto.name && dto.name !== existing.name) {
      await this.assertNameAvailable(dto.name);
    }

    const data: Prisma.ThemeUpdateInput = {
      name: dto.name,
      description: dto.description,
    };

    // Only a token change bumps the revision — renaming a theme shouldn't force
    // every till in the shop to re-download an identical token payload.
    if (dto.tokens) {
      this.assertValidTokens(dto.tokens);
      data.tokens = dto.tokens as Prisma.InputJsonValue;
      data.revision = { increment: 1 };
    }

    return this.repo.update(id, data);
  }

  async duplicate(id: string, dto: DuplicateThemeDto, userId: string): Promise<Theme> {
    const source = await this.findOne(id);
    await this.assertNameAvailable(dto.name);

    return this.repo.create({
      name: dto.name,
      description: source.description,
      tokens: source.tokens as Prisma.InputJsonValue,
      schemaVersion: source.schemaVersion,
      revision: 1,
      createdBy: { connect: { id: userId } },
    });
  }

  async remove(id: string): Promise<void> {
    await this.findOne(id);

    // A soft-deleted theme that's still live on a platform would leave that
    // platform pointing at a hidden record — block it and tell the admin which
    // platforms to reassign first.
    const platforms = await this.repo.findPlatformsUsingTheme(id);
    if (platforms.length) {
      throw new ConflictException(
        `Theme is live on ${platforms.join(', ')}. Assign a different theme to those platforms first.`,
      );
    }

    await this.repo.softDelete(id);
  }

  // --- Assignments ----------------------------------------------------------

  async listAssignments() {
    return this.repo.findAllAssignments();
  }

  async assign(platform: Platform, dto: AssignThemeDto, userId: string) {
    await this.findOne(dto.themeId); // 404s if the theme doesn't exist
    return this.repo.upsertAssignment(platform, dto.themeId, userId);
  }

  /**
   * What a client should boot with. Returns null when no theme has been
   * assigned to the platform yet — the controller turns that into a 404 so the
   * client keeps its cached tokens rather than painting an empty theme.
   */
  async findActiveForPlatform(platform: Platform) {
    const assignment = await this.repo.findAssignment(platform);
    if (!assignment) return null;

    const { theme } = assignment;
    return {
      id: theme.id,
      name: theme.name,
      revision: theme.revision,
      schemaVersion: theme.schemaVersion,
      tokens: theme.tokens,
      /** Clients send this back as If-None-Match to skip unchanged payloads. */
      etag: `"${theme.id}:${theme.revision}"`,
    };
  }

  // --- helpers --------------------------------------------------------------

  private assertValidTokens(tokens: unknown): void {
    try {
      validateTokenPayload(tokens);
    } catch (err) {
      if (err instanceof TokenValidationError) {
        // Surface every problem at once so the editor can highlight all the bad
        // fields instead of making the admin fix one per save.
        throw new BadRequestException({ message: err.message, issues: err.issues });
      }
      throw err;
    }
  }

  private async assertNameAvailable(name: string): Promise<void> {
    if (await this.repo.findByName(name)) {
      throw new ConflictException(`A theme named "${name}" already exists`);
    }
  }
}
