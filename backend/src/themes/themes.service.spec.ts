import { BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
import { Platform } from '@prisma/client';

import { validateTokenPayload, TokenValidationError } from './theme-tokens.schema';
import { ThemesService } from './themes.service';

// Minimal valid mode used to build fixtures.
const mode = () => ({
  color: {
    background: {
      canvas: '#FFFFFF', surface: '#F6F7F9', raised: '#FFFFFF', inverse: '#111318',
      accent: '#2F6BFF', danger: '#D22D2D', success: '#1E8E5A', warning: '#B87503',
    },
    content: {
      primary: '#111318', secondary: '#5A6272', muted: '#8A92A3',
      onAccent: '#FFFFFF', onInverse: '#F6F7F9', danger: '#D22D2D',
    },
    border: {
      subtle: '#E4E7EC', default: '#CBD1DA', strong: '#98A1B0',
      accent: '#2F6BFF', focus: '#2F6BFF',
    },
  },
  spacing: { 0: 0, 1: 4, 2: 8, 3: 12, 4: 16, 5: 24, 6: 32, 7: 48, 8: 64 },
  radius: { none: 0, sm: 4, md: 8, lg: 16, pill: 999 },
  borderWidth: { none: 0, hairline: 1, thick: 2 },
  typography: {
    fontFamily: { display: 'Inter', body: 'Inter', mono: 'RobotoMono' },
    scale: {
      display: { size: 32, weight: 700, height: 1.2, letterSpacing: -0.5 },
      title: { size: 22, weight: 600, height: 1.3, letterSpacing: 0 },
      body: { size: 15, weight: 400, height: 1.45, letterSpacing: 0 },
      label: { size: 13, weight: 500, height: 1.3, letterSpacing: 0.2 },
      caption: { size: 11, weight: 400, height: 1.3, letterSpacing: 0.4 },
      mono: { size: 14, weight: 400, height: 1.4, letterSpacing: 0 },
    },
  },
  elevation: { none: 0, sm: 1, md: 4, lg: 12 },
});

const validTokens = () => ({ schemaVersion: 1, modes: { light: mode(), dark: mode() } });

describe('validateTokenPayload', () => {
  it('accepts a complete payload', () => {
    expect(() => validateTokenPayload(validTokens())).not.toThrow();
  });

  it('rejects a missing colour key rather than defaulting it', () => {
    const tokens = validTokens();
    delete (tokens.modes.light.color.background as Record<string, unknown>).accent;

    expect(() => validateTokenPayload(tokens)).toThrow(TokenValidationError);
    try {
      validateTokenPayload(tokens);
    } catch (err) {
      expect((err as TokenValidationError).issues).toContainEqual(
        expect.stringContaining('modes.light.color.background.accent'),
      );
    }
  });

  it('rejects a malformed hex value', () => {
    const tokens = validTokens();
    tokens.modes.light.color.content.primary = 'navy' as never;
    expect(() => validateTokenPayload(tokens)).toThrow(TokenValidationError);
  });

  it('accepts 8-digit alpha hex', () => {
    const tokens = validTokens();
    tokens.modes.light.color.border.subtle = '#80E4E7EC';
    expect(() => validateTokenPayload(tokens)).not.toThrow();
  });

  it('rejects a font weight that is not a multiple of 100', () => {
    const tokens = validTokens();
    tokens.modes.light.typography.scale.body.weight = 450;
    expect(() => validateTokenPayload(tokens)).toThrow(TokenValidationError);
  });

  it('rejects a missing dark mode — both modes are required', () => {
    const tokens = validTokens();
    delete (tokens.modes as Record<string, unknown>).dark;
    expect(() => validateTokenPayload(tokens)).toThrow(TokenValidationError);
  });

  it('rejects an unknown schema version so old clients fail loudly', () => {
    const tokens = { ...validTokens(), schemaVersion: 99 };
    expect(() => validateTokenPayload(tokens)).toThrow(TokenValidationError);
  });

  it('reports every problem at once, not just the first', () => {
    const tokens = validTokens();
    tokens.modes.light.color.content.primary = 'nope' as never;
    tokens.modes.light.spacing[4] = 'wide' as never;
    tokens.modes.dark.radius.md = -1;

    try {
      validateTokenPayload(tokens);
      fail('expected a validation error');
    } catch (err) {
      expect((err as TokenValidationError).issues.length).toBeGreaterThanOrEqual(3);
    }
  });
});

describe('ThemesService', () => {
  let repo: jest.Mocked<any>;
  let service: ThemesService;

  beforeEach(() => {
    repo = {
      findById: jest.fn(),
      findByName: jest.fn().mockResolvedValue(null),
      create: jest.fn().mockImplementation((data) => Promise.resolve({ id: 'new', ...data })),
      update: jest.fn().mockImplementation((id, data) => Promise.resolve({ id, ...data })),
      softDelete: jest.fn(),
      findPlatformsUsingTheme: jest.fn().mockResolvedValue([]),
      findAssignment: jest.fn(),
      upsertAssignment: jest.fn(),
    };
    service = new ThemesService(repo);
  });

  it('rejects invalid tokens with the field-level issues attached', async () => {
    await expect(
      service.create({ name: 'Broken', tokens: { schemaVersion: 1 } as never }, 'user-1'),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects a duplicate theme name', async () => {
    repo.findByName.mockResolvedValue({ id: 'existing' });
    await expect(
      service.create({ name: 'Daylight', tokens: validTokens() }, 'user-1'),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('bumps the revision when tokens change', async () => {
    repo.findById.mockResolvedValue({ id: 't1', name: 'Daylight' });
    await service.update('t1', { tokens: validTokens() });

    expect(repo.update).toHaveBeenCalledWith('t1', expect.objectContaining({
      revision: { increment: 1 },
    }));
  });

  it('does not bump the revision for a rename — clients should not re-download', async () => {
    repo.findById.mockResolvedValue({ id: 't1', name: 'Daylight' });
    await service.update('t1', { name: 'Daytime' });

    const [, data] = repo.update.mock.calls[0];
    expect(data.revision).toBeUndefined();
  });

  it('refuses to delete a theme that is live on a platform', async () => {
    repo.findById.mockResolvedValue({ id: 't1', name: 'Daylight' });
    repo.findPlatformsUsingTheme.mockResolvedValue([Platform.WEB, Platform.IOS]);

    await expect(service.remove('t1')).rejects.toBeInstanceOf(ConflictException);
    expect(repo.softDelete).not.toHaveBeenCalled();
  });

  it('404s for an unknown theme', async () => {
    repo.findById.mockResolvedValue(null);
    await expect(service.findOne('missing')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('builds an ETag from the theme id and revision', async () => {
    repo.findAssignment.mockResolvedValue({
      theme: { id: 't1', name: 'Daylight', revision: 7, schemaVersion: 1, tokens: validTokens() },
    });

    const active = await service.findActiveForPlatform(Platform.WEB);
    expect(active?.etag).toBe('"t1:7"');
  });

  it('returns null when a platform has no assignment', async () => {
    repo.findAssignment.mockResolvedValue(null);
    expect(await service.findActiveForPlatform(Platform.ANDROID)).toBeNull();
  });
});
