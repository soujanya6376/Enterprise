import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtPayload } from './jwt.strategy';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService,
  ) {}

  async validateUser(username: string, password: string) {
    const user = await this.prisma.user.findFirst({
      where: { username, deletedAt: null },
      include: { role: true },
    });
    if (!user || !user.isActive) throw new UnauthorizedException('Invalid credentials');
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) throw new UnauthorizedException('Invalid credentials');
    return user;
  }

  private async issueTokens(user: { id: string; username: string; tokenVersion: number; role: { name: string } }) {
    const payload: JwtPayload = {
      sub: user.id,
      username: user.username,
      role: user.role.name as 'ADMIN' | 'USER',
      tokenVersion: user.tokenVersion,
    };
    const accessToken = await this.jwt.signAsync(payload, {
      secret: this.config.get('JWT_ACCESS_SECRET'),
      expiresIn: this.config.get('JWT_ACCESS_EXPIRES', '15m'),
    });
    const refreshToken = await this.jwt.signAsync(payload, {
      secret: this.config.get('JWT_REFRESH_SECRET'),
      expiresIn: this.config.get('JWT_REFRESH_EXPIRES', '7d'),
    });
    return { accessToken, refreshToken };
  }

  async login(username: string, password: string) {
    const user = await this.validateUser(username, password);
    const tokens = await this.issueTokens(user);
    return {
      ...tokens,
      user: { id: user.id, username: user.username, email: user.email, role: user.role.name },
    };
  }

  async refresh(refreshToken: string) {
    let payload: JwtPayload;
    try {
      payload = await this.jwt.verifyAsync(refreshToken, {
        secret: this.config.get('JWT_REFRESH_SECRET'),
      });
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
    const user = await this.prisma.user.findFirst({
      where: { id: payload.sub, deletedAt: null, isActive: true },
      include: { role: true },
    });
    if (!user || user.tokenVersion !== payload.tokenVersion) {
      throw new UnauthorizedException('Refresh token revoked');
    }
    const accessToken = await this.jwt.signAsync(
      { sub: user.id, username: user.username, role: user.role.name, tokenVersion: user.tokenVersion },
      { secret: this.config.get('JWT_ACCESS_SECRET'), expiresIn: this.config.get('JWT_ACCESS_EXPIRES', '15m') },
    );
    return { accessToken };
  }

  /** Revoke all refresh tokens by bumping tokenVersion. */
  async logout(userId: string) {
    await this.prisma.user.update({ where: { id: userId }, data: { tokenVersion: { increment: 1 } } });
    return { success: true };
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, include: { role: true } });
    if (!user) throw new UnauthorizedException();
    return { id: user.id, username: user.username, email: user.email, role: user.role.name };
  }
}
