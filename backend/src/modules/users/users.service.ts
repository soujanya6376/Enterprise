import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { PaginationDto, buildMeta } from '../../common/dto/pagination.dto';
import { CreateUserDto, UpdateUserDto } from './dto/user.dto';

const SAFE_SELECT = {
  id: true,
  username: true,
  email: true,
  isActive: true,
  createdAt: true,
  updatedAt: true,
  role: { select: { name: true } },
};

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  private async roleIdByName(name: string) {
    const role = await this.prisma.role.findUnique({ where: { name } });
    if (!role) throw new BadRequestException(`Unknown role: ${name}`);
    return role.id;
  }

  async findAll(q: PaginationDto) {
    const where: Prisma.UserWhereInput = {
      deletedAt: null,
      ...(q.search
        ? { OR: [{ username: { contains: q.search, mode: 'insensitive' } }, { email: { contains: q.search, mode: 'insensitive' } }] }
        : {}),
    };
    const [data, total] = await this.prisma.$transaction([
      this.prisma.user.findMany({ where, select: SAFE_SELECT, skip: q.skip, take: q.limit, orderBy: { createdAt: 'desc' } }),
      this.prisma.user.count({ where }),
    ]);
    return { data, meta: buildMeta(total, q.page, q.limit) };
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findFirst({ where: { id, deletedAt: null }, select: SAFE_SELECT });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async create(dto: CreateUserDto) {
    const roleId = await this.roleIdByName(dto.roleName);
    const passwordHash = await bcrypt.hash(dto.password, 10);
    return this.prisma.user.create({
      data: { username: dto.username, email: dto.email, passwordHash, roleId },
      select: SAFE_SELECT,
    });
  }

  async update(id: string, dto: UpdateUserDto) {
    await this.findOne(id);
    const data: Prisma.UserUpdateInput = {};
    if (dto.email !== undefined) data.email = dto.email;
    if (dto.isActive !== undefined) data.isActive = dto.isActive;
    if (dto.roleName) data.role = { connect: { id: await this.roleIdByName(dto.roleName) } };
    if (dto.password) data.passwordHash = await bcrypt.hash(dto.password, 10);
    return this.prisma.user.update({ where: { id }, data, select: SAFE_SELECT });
  }

  async resetPassword(id: string, newPassword: string) {
    await this.findOne(id);
    const passwordHash = await bcrypt.hash(newPassword, 10);
    await this.prisma.user.update({
      where: { id },
      data: { passwordHash, tokenVersion: { increment: 1 } }, // force re-login
    });
    return { success: true };
  }

  async remove(id: string) {
    await this.findOne(id);
    await this.prisma.user.update({ where: { id }, data: { deletedAt: new Date(), isActive: false } });
    return { success: true };
  }
}
