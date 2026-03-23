'use client';

import { useState, useEffect, useRef } from 'react';
import type { FilterPresetId } from '@/lib/types';

interface PresetInfo {
  id: FilterPresetId;
  label: string;
  description: string;
  matchCount: number;
  active: boolean;
}

interface PreferencesPanelProps {
  open: boolean;
  onClose: () => void;
  onPresetsChanged: () => void;
}

export function PreferencesPanel({ open, onClose, onPresetsChanged }: PreferencesPanelProps) {
  const [presets, setPresets] = useState<PresetInfo[]>([]);
  const [watchDirs, setWatchDirs] = useState<string[]>([]);
  const [customDirs, setCustomDirs] = useState<string[]>([]);
  const [disabledDirs, setDisabledDirs] = useState<Set<string>>(new Set());
  const [minFileLength, setMinFileLength] = useState(0);
  const [loading, setLoading] = useState(true);
  const panelRef = useRef<HTMLDivElement>(null);
  const minFileLengthTimer = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (!open) return;
    setLoading(true);
    fetch('/api/preferences')
      .then(r => r.json())
      .then(data => {
        setPresets(data.presets || []);
        setWatchDirs(data.watchDirs || []);
        setCustomDirs(data.customWatchDirs || []);
        setMinFileLength(data.minFileLength || 0);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose(); };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [open, onClose]);

  useEffect(() => {
    if (!open) return;
    const handler = (e: MouseEvent) => {
      if (panelRef.current && !panelRef.current.contains(e.target as Node)) onClose();
    };
    const timeout = setTimeout(() => document.addEventListener('mousedown', handler), 100);
    return () => { clearTimeout(timeout); document.removeEventListener('mousedown', handler); };
  }, [open, onClose]);

  const handleTogglePreset = async (presetId: FilterPresetId) => {
    const res = await fetch('/api/preferences', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ togglePreset: presetId }),
    });
    const data = await res.json();
    setPresets(prev => prev.map(p => p.id === presetId ? { ...p, active: data.active } : p));
    onPresetsChanged();
  };

  const handleRemoveDir = async (dir: string) => {
    await fetch('/api/preferences', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ removeWatchDir: dir }),
    });
    setWatchDirs(prev => prev.filter(d => d !== dir));
    setCustomDirs(prev => prev.filter(d => d !== dir));
    onPresetsChanged();
  };

  const handleToggleDir = async (dir: string) => {
    const isCurrentlyDisabled = disabledDirs.has(dir);
    if (isCurrentlyDisabled) {
      // Re-enable: add it back as a watch dir
      await fetch('/api/preferences', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ addWatchDir: dir }),
      });
      setDisabledDirs(prev => { const n = new Set(prev); n.delete(dir); return n; });
      if (!watchDirs.includes(dir)) setWatchDirs(prev => [...prev, dir]);
    } else {
      // Disable: remove from watcher but keep in list as disabled
      await fetch('/api/preferences', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ removeWatchDir: dir }),
      });
      setDisabledDirs(prev => new Set(prev).add(dir));
      setWatchDirs(prev => prev.filter(d => d !== dir));
    }
    onPresetsChanged();
  };

  const handleBrowse = async () => {
    const electron = (window as unknown as { electron?: { selectFolder: () => Promise<string | null> } }).electron;
    if (electron?.selectFolder) {
      const dir = await electron.selectFolder();
      if (dir) {
        await fetch('/api/preferences', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ addWatchDir: dir }),
        });
        setCustomDirs(prev => [...prev, dir]);
        setWatchDirs(prev => [...prev, dir]);
        onPresetsChanged();
      }
    }
  };

  if (!open) return null;

  const activeCount = presets.filter(p => p.active).length;
  const hiddenCount = presets.filter(p => p.active).reduce((sum, p) => sum + p.matchCount, 0);

  // Build a unified list of all dirs (active + disabled)
  const allDirs = [...new Set([...watchDirs, ...Array.from(disabledDirs)])];

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-16" style={{ background: 'rgba(0,0,0,0.6)' }}>
      <div
        ref={panelRef}
        className="w-full max-w-lg rounded-xl border overflow-hidden"
        style={{ background: 'var(--surface)', borderColor: 'var(--border)' }}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-3 border-b" style={{ borderColor: 'var(--border)' }}>
          <h2 className="text-sm font-semibold" style={{ fontFamily: 'var(--font-jetbrains-mono), monospace', color: 'var(--text)' }}>
            Preferences
          </h2>
          <button className="tab-btn text-xs" onClick={onClose}>✕</button>
        </div>

        <div className="max-h-[70vh] overflow-y-auto">
          {loading ? (
            <div className="p-5">
              <div className="skeleton h-4 w-1/3 mb-3" />
              <div className="skeleton h-8 w-full mb-2" />
              <div className="skeleton h-8 w-full mb-2" />
              <div className="skeleton h-8 w-full" />
            </div>
          ) : (
            <>
              {/* Hidden file filters — consistent semantics: checked = hidden */}
              <div className="px-5 py-4">
                <div className="flex items-baseline justify-between mb-2">
                  <h3 className="text-xs font-medium uppercase tracking-wider" style={{ color: 'var(--text-muted)' }}>
                    Hide from sidebar
                  </h3>
                  <span className="text-[10px]" style={{ color: 'var(--text-muted)' }}>
                    {activeCount} active · {hiddenCount} files hidden
                  </span>
                </div>
                <p className="text-[10px] mb-3" style={{ color: 'var(--text-muted)' }}>
                  Checked items are hidden from the file list.
                </p>

                {/* Min file length */}
                <div
                  className="px-3 py-2.5 rounded-lg mb-3"
                  style={{ border: `1px solid ${minFileLength > 0 ? 'var(--accent)' : 'var(--border)'}`, background: minFileLength > 0 ? 'var(--active-bg)' : 'transparent' }}
                >
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="text-xs font-medium" style={{ fontFamily: 'var(--font-jetbrains-mono), monospace', color: 'var(--text)' }}>
                      Minimum file size
                    </span>
                    <span className="text-[10px]" style={{ color: minFileLength > 0 ? 'var(--accent)' : 'var(--text-muted)' }}>
                      {minFileLength === 0 ? 'Off' : minFileLength < 1024 ? `${minFileLength} B` : `${(minFileLength / 1024).toFixed(1)} KB`}
                    </span>
                  </div>
                  <input
                    type="range" min={0} max={5120} step={64} value={minFileLength}
                    onChange={(e) => {
                      const val = Number(e.target.value);
                      setMinFileLength(val);
                      if (minFileLengthTimer.current) clearTimeout(minFileLengthTimer.current);
                      minFileLengthTimer.current = setTimeout(() => {
                        fetch('/api/preferences', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ minFileLength: val }) })
                          .then(() => onPresetsChanged()).catch(() => {});
                      }, 300);
                    }}
                    className="w-full" style={{ accentColor: 'var(--accent)', height: 4 }}
                  />
                </div>

                {/* Presets */}
                {(() => {
                  const genericPresets = presets.filter(p => !p.id.startsWith('claude-'));
                  const claudePresets = presets.filter(p => p.id.startsWith('claude-'));

                  const renderPreset = (preset: PresetInfo) => (
                    <button
                      key={preset.id}
                      className="flex items-center gap-3 px-3 py-2 rounded-lg text-left transition-colors"
                      style={{
                        background: preset.active ? 'var(--active-bg)' : 'transparent',
                        border: `1px solid ${preset.active ? 'var(--accent)' : 'var(--border)'}`,
                        opacity: preset.matchCount === 0 && !preset.active ? 0.45 : 1,
                      }}
                      onClick={() => handleTogglePreset(preset.id)}
                    >
                      <span
                        className="w-4 h-4 rounded flex items-center justify-center text-[10px] shrink-0"
                        style={{
                          background: preset.active ? 'var(--accent)' : 'transparent',
                          border: `1.5px solid ${preset.active ? 'var(--accent)' : 'var(--border)'}`,
                          color: preset.active ? 'var(--bg)' : 'transparent',
                        }}
                      >
                        ✓
                      </span>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-medium" style={{ fontFamily: 'var(--font-jetbrains-mono), monospace', color: 'var(--text)' }}>
                            {preset.label}
                          </span>
                          {preset.matchCount > 0 && (
                            <span className="text-[10px] px-1.5 rounded" style={{
                              background: preset.active ? 'rgba(212,160,74,0.2)' : 'var(--hover-bg)',
                              color: preset.active ? 'var(--accent)' : 'var(--text-muted)',
                            }}>
                              {preset.matchCount}
                            </span>
                          )}
                        </div>
                        <p className="text-[10px] mt-0.5" style={{ color: 'var(--text-muted)' }}>{preset.description}</p>
                      </div>
                    </button>
                  );

                  return (
                    <>
                      {genericPresets.length > 0 && (
                        <div className="mb-3">
                          <p className="text-[10px] uppercase tracking-wider mb-1.5" style={{ color: 'var(--text-muted)' }}>General</p>
                          <div className="flex flex-col gap-1">{genericPresets.map(renderPreset)}</div>
                        </div>
                      )}
                      {claudePresets.length > 0 && (
                        <div>
                          <p className="text-[10px] uppercase tracking-wider mb-1.5" style={{ color: 'var(--text-muted)' }}>Claude Code</p>
                          <div className="flex flex-col gap-1">{claudePresets.map(renderPreset)}</div>
                        </div>
                      )}
                    </>
                  );
                })()}
              </div>

              {/* Watch directories */}
              <div className="px-5 py-4 border-t" style={{ borderColor: 'var(--border)' }}>
                <h3 className="text-xs font-medium uppercase tracking-wider mb-3" style={{ color: 'var(--text-muted)' }}>
                  Watch Directories
                </h3>

                <div className="flex flex-col gap-1.5 mb-3">
                  {allDirs.map(dir => {
                    const isDisabled = disabledDirs.has(dir);
                    return (
                      <div
                        key={dir}
                        className="flex items-center gap-2 px-3 py-1.5 rounded group"
                        style={{ background: 'var(--hover-bg)', opacity: isDisabled ? 0.5 : 1 }}
                      >
                        <span
                          className="text-xs flex-1 truncate"
                          style={{
                            fontFamily: 'var(--font-jetbrains-mono), monospace',
                            color: isDisabled ? 'var(--text-muted)' : 'var(--text)',
                            textDecoration: isDisabled ? 'line-through' : 'none',
                          }}
                        >
                          {dir.replace(/^\/Users\/[^/]+/, '~')}
                        </span>
                        <button
                          className="text-[10px] px-1.5 py-0.5 rounded hover:bg-[var(--border)] transition-colors"
                          style={{ color: isDisabled ? 'var(--accent)' : 'var(--text-muted)' }}
                          onClick={() => handleToggleDir(dir)}
                          title={isDisabled ? 'Re-enable this folder' : 'Temporarily hide files from this folder'}
                        >
                          {isDisabled ? 'Enable' : 'Disable'}
                        </button>
                        <button
                          className="text-[10px] px-1.5 py-0.5 rounded hover:bg-[var(--border)] transition-colors"
                          style={{ color: '#f87171' }}
                          onClick={() => handleRemoveDir(dir)}
                          title="Permanently remove this folder"
                        >
                          Remove
                        </button>
                      </div>
                    );
                  })}
                </div>

                <button
                  className="filter-pill text-xs"
                  onClick={handleBrowse}
                  style={{ padding: '4px 12px' }}
                >
                  + Add Folder
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
