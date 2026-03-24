export interface TypographyPreset {
  id: string;
  label: string;
  description: string;
  vars: {
    '--font-heading': string;
    '--font-body': string;
    '--font-ui': string;
    '--font-mono': string;
    '--prose-font-size'?: string;
    '--prose-line-height'?: string;
    '--prose-letter-spacing'?: string;
  };
}

export const TYPOGRAPHY_PRESETS: TypographyPreset[] = [
  {
    id: 'classic',
    label: 'Classic',
    description: 'Source Serif 4 for prose, system sans for UI',
    vars: {
      '--font-heading': "'Source Serif 4', Georgia, serif",
      '--font-body': "'Source Serif 4', Georgia, serif",
      '--font-ui': "-apple-system, BlinkMacSystemFont, system-ui, sans-serif",
      '--font-mono': "'JetBrains Mono', 'SF Mono', Menlo, monospace",
    },
  },
  {
    id: 'modern',
    label: 'Modern',
    description: 'System sans-serif everywhere, clean and minimal',
    vars: {
      '--font-heading': "-apple-system, BlinkMacSystemFont, 'SF Pro Display', system-ui, sans-serif",
      '--font-body': "-apple-system, BlinkMacSystemFont, 'SF Pro Text', system-ui, sans-serif",
      '--font-ui': "-apple-system, BlinkMacSystemFont, system-ui, sans-serif",
      '--font-mono': "'JetBrains Mono', 'SF Mono', Menlo, monospace",
    },
  },
  {
    id: 'literary',
    label: 'Literary',
    description: 'Elegant serif throughout, for long-form reading',
    vars: {
      '--font-heading': "'Source Serif 4', 'Palatino Linotype', Palatino, serif",
      '--font-body': "'Source Serif 4', 'Palatino Linotype', Palatino, serif",
      '--font-ui': "'Source Serif 4', Georgia, serif",
      '--font-mono': "'JetBrains Mono', 'SF Mono', Menlo, monospace",
    },
  },
  {
    id: 'developer',
    label: 'Developer',
    description: 'JetBrains Mono everywhere, for code-heavy docs',
    vars: {
      '--font-heading': "'JetBrains Mono', 'SF Mono', Menlo, monospace",
      '--font-body': "'JetBrains Mono', 'SF Mono', Menlo, monospace",
      '--font-ui': "'JetBrains Mono', 'SF Mono', Menlo, monospace",
      '--font-mono': "'JetBrains Mono', 'SF Mono', Menlo, monospace",
    },
  },
  {
    id: 'accessible',
    label: 'Accessible',
    description: 'Optimized for readability and dyslexia',
    vars: {
      '--font-heading': "-apple-system, BlinkMacSystemFont, system-ui, sans-serif",
      '--font-body': "-apple-system, BlinkMacSystemFont, system-ui, sans-serif",
      '--font-ui': "-apple-system, BlinkMacSystemFont, system-ui, sans-serif",
      '--font-mono': "'JetBrains Mono', 'SF Mono', Menlo, monospace",
      '--prose-font-size': '19px',
      '--prose-line-height': '1.8',
      '--prose-letter-spacing': '0.01em',
    },
  },
];

export const DEFAULT_TYPOGRAPHY_ID = 'classic';

export function getTypographyPreset(id: string): TypographyPreset {
  return TYPOGRAPHY_PRESETS.find(p => p.id === id) || TYPOGRAPHY_PRESETS[0];
}

export function applyTypographyPreset(preset: TypographyPreset): void {
  const root = document.documentElement;
  for (const [key, value] of Object.entries(preset.vars)) {
    root.style.setProperty(key, value);
  }
  // Clear optional vars if not set by this preset
  if (!preset.vars['--prose-font-size']) root.style.removeProperty('--prose-font-size');
  if (!preset.vars['--prose-line-height']) root.style.removeProperty('--prose-line-height');
  if (!preset.vars['--prose-letter-spacing']) root.style.removeProperty('--prose-letter-spacing');
}

const STORAGE_KEY = 'markscout-typography';

export function loadSavedTypography(): string {
  try {
    return localStorage.getItem(STORAGE_KEY) || DEFAULT_TYPOGRAPHY_ID;
  } catch {
    return DEFAULT_TYPOGRAPHY_ID;
  }
}

export function saveTypography(id: string): void {
  try {
    localStorage.setItem(STORAGE_KEY, id);
  } catch {
    // ignore
  }
}
