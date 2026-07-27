/**
 * Canonical v1 token contract.
 *
 * This file is the single source of truth for what a valid token payload looks
 * like. The Flutter client's ThemeTokens model mirrors it exactly — if you add a
 * key here, add it there, bump SCHEMA_VERSION, and write a migration that
 * backfills every stored theme. Never add an optional key with a silent default:
 * a half-defined theme reaching a till screen is worse than a rejected save.
 */

export const SCHEMA_VERSION = 1;

export type TokenMode = 'light' | 'dark';
export const TOKEN_MODES: TokenMode[] = ['light', 'dark'];

/** group -> required keys */
const COLOR_GROUPS = {
  background: ['canvas', 'surface', 'raised', 'inverse', 'accent', 'danger', 'success', 'warning'],
  content: ['primary', 'secondary', 'muted', 'onAccent', 'onInverse', 'danger'],
  border: ['subtle', 'default', 'strong', 'accent', 'focus'],
} as const;

const SPACING_KEYS = ['0', '1', '2', '3', '4', '5', '6', '7', '8'] as const;
const RADIUS_KEYS = ['none', 'sm', 'md', 'lg', 'pill'] as const;
const BORDER_WIDTH_KEYS = ['none', 'hairline', 'thick'] as const;
const ELEVATION_KEYS = ['none', 'sm', 'md', 'lg'] as const;
const FONT_ROLES = ['display', 'body', 'mono'] as const;
const TYPE_ROLES = ['display', 'title', 'body', 'label', 'caption', 'mono'] as const;
const TYPE_FIELDS = ['size', 'weight', 'height', 'letterSpacing'] as const;

const HEX = /^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/;

export class TokenValidationError extends Error {
  constructor(public readonly issues: string[]) {
    super(`Invalid theme tokens: ${issues.length} problem(s)`);
  }
}

function isPlainObject(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

function checkNumber(
  value: unknown,
  path: string,
  issues: string[],
  opts: { min?: number; max?: number; integer?: boolean } = {},
) {
  if (typeof value !== 'number' || Number.isNaN(value)) {
    issues.push(`${path}: expected a number, got ${JSON.stringify(value)}`);
    return;
  }
  if (opts.integer && !Number.isInteger(value)) issues.push(`${path}: must be a whole number`);
  if (opts.min !== undefined && value < opts.min) issues.push(`${path}: must be >= ${opts.min}`);
  if (opts.max !== undefined && value > opts.max) issues.push(`${path}: must be <= ${opts.max}`);
}

function validateMode(mode: unknown, path: string, issues: string[]): void {
  if (!isPlainObject(mode)) {
    issues.push(`${path}: expected an object`);
    return;
  }

  // --- colour ---
  const color = mode.color;
  if (!isPlainObject(color)) {
    issues.push(`${path}.color: expected an object`);
  } else {
    for (const [group, keys] of Object.entries(COLOR_GROUPS)) {
      const bucket = color[group];
      if (!isPlainObject(bucket)) {
        issues.push(`${path}.color.${group}: expected an object`);
        continue;
      }
      for (const key of keys) {
        const raw = bucket[key];
        if (typeof raw !== 'string' || !HEX.test(raw)) {
          issues.push(`${path}.color.${group}.${key}: expected #RRGGBB or #AARRGGBB, got ${JSON.stringify(raw)}`);
        }
      }
    }
  }

  // --- numeric scales ---
  const scales: Array<[string, readonly string[], { min: number; max: number }]> = [
    ['spacing', SPACING_KEYS, { min: 0, max: 256 }],
    ['radius', RADIUS_KEYS, { min: 0, max: 999 }],
    ['borderWidth', BORDER_WIDTH_KEYS, { min: 0, max: 16 }],
    ['elevation', ELEVATION_KEYS, { min: 0, max: 48 }],
  ];
  for (const [group, keys, bounds] of scales) {
    const bucket = mode[group];
    if (!isPlainObject(bucket)) {
      issues.push(`${path}.${group}: expected an object`);
      continue;
    }
    for (const key of keys) checkNumber(bucket[key], `${path}.${group}.${key}`, issues, bounds);
  }

  // --- typography ---
  const typography = mode.typography;
  if (!isPlainObject(typography)) {
    issues.push(`${path}.typography: expected an object`);
    return;
  }

  const fontFamily = typography.fontFamily;
  if (!isPlainObject(fontFamily)) {
    issues.push(`${path}.typography.fontFamily: expected an object`);
  } else {
    for (const role of FONT_ROLES) {
      if (typeof fontFamily[role] !== 'string' || !(fontFamily[role] as string).trim()) {
        issues.push(`${path}.typography.fontFamily.${role}: expected a non-empty font family name`);
      }
    }
  }

  const scale = typography.scale;
  if (!isPlainObject(scale)) {
    issues.push(`${path}.typography.scale: expected an object`);
  } else {
    for (const role of TYPE_ROLES) {
      const entry = scale[role];
      if (!isPlainObject(entry)) {
        issues.push(`${path}.typography.scale.${role}: expected an object`);
        continue;
      }
      for (const field of TYPE_FIELDS) {
        const p = `${path}.typography.scale.${role}.${field}`;
        switch (field) {
          case 'size':
            checkNumber(entry[field], p, issues, { min: 1, max: 200 });
            break;
          case 'weight':
            checkNumber(entry[field], p, issues, { min: 100, max: 900, integer: true });
            if (typeof entry[field] === 'number' && (entry[field] as number) % 100 !== 0) {
              issues.push(`${p}: must be a multiple of 100`);
            }
            break;
          case 'height':
            checkNumber(entry[field], p, issues, { min: 0.5, max: 4 });
            break;
          case 'letterSpacing':
            checkNumber(entry[field], p, issues, { min: -10, max: 10 });
            break;
        }
      }
    }
  }
}

/**
 * Validates a full token payload. Throws TokenValidationError listing every
 * problem found — the editor shows all of them at once rather than making the
 * admin fix one field per save.
 */
export function validateTokenPayload(payload: unknown): void {
  const issues: string[] = [];

  if (!isPlainObject(payload)) {
    throw new TokenValidationError(['tokens: expected an object']);
  }

  if (payload.schemaVersion !== SCHEMA_VERSION) {
    issues.push(`tokens.schemaVersion: expected ${SCHEMA_VERSION}, got ${JSON.stringify(payload.schemaVersion)}`);
  }

  const modes = payload.modes;
  if (!isPlainObject(modes)) {
    issues.push('tokens.modes: expected an object with "light" and "dark"');
  } else {
    for (const mode of TOKEN_MODES) validateMode(modes[mode], `tokens.modes.${mode}`, issues);
    for (const key of Object.keys(modes)) {
      if (!TOKEN_MODES.includes(key as TokenMode)) issues.push(`tokens.modes.${key}: unknown mode`);
    }
  }

  if (issues.length) throw new TokenValidationError(issues);
}
