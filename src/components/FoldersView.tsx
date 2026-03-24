import { useState, useCallback, useEffect, useRef } from 'react';
import type { FileEntry, FolderNode } from '../lib/types';
import { FileItem } from './FileItem';

interface FoldersViewProps {
  folders: FolderNode[];
  selectedPath: string | null;
  onSelectFile: (path: string) => void;
  onToggleStar: (path: string) => void;
  favorites: Set<string>;
  favoriteFolders: Set<string>;
  onToggleFolderStar: (folderPath: string) => void;
  expandedGroups: Set<string>;
  onToggleExpand: (folderPath: string) => void;
  excludedPaths: Set<string>;
  onExcludeFolder: (folderPath: string) => void;
  onIncludeFolder: (folderPath: string) => void;
  customWatchDirs?: string[];
  onRemoveWatchDir?: (dir: string) => void;
}

interface ContextMenuState {
  x: number;
  y: number;
  folderPath: string;
  isExcluded: boolean;
}

// Indent constants
const BASE_INDENT = 10;
const INDENT_PER_DEPTH = 14;

function folderIndent(depth: number) {
  return BASE_INDENT + depth * INDENT_PER_DEPTH;
}

function fileIndent(depth: number) {
  return BASE_INDENT + (depth + 1) * INDENT_PER_DEPTH;
}

function FolderGroup({
  node,
  depth,
  selectedPath,
  onSelectFile,
  onToggleStar,
  favorites,
  favoriteFolders,
  onToggleFolderStar,
  expandedGroups,
  onToggleExpand,
  excludedPaths,
  onContextMenu,
  isWatchRoot,
  onRemoveWatchDir,
}: {
  node: FolderNode;
  depth: number;
  selectedPath: string | null;
  onSelectFile: (path: string) => void;
  onToggleStar: (path: string) => void;
  favorites: Set<string>;
  favoriteFolders: Set<string>;
  onToggleFolderStar: (folderPath: string) => void;
  expandedGroups: Set<string>;
  onToggleExpand: (folderPath: string) => void;
  excludedPaths: Set<string>;
  onContextMenu: (e: React.MouseEvent, folderPath: string, isExcluded: boolean) => void;
  isWatchRoot?: boolean;
  onRemoveWatchDir?: (dir: string) => void;
}) {
  const isExpanded = expandedGroups.has(node.path);
  const isFolderStarred = favoriteFolders.has(node.path);
  const isExcluded = excludedPaths.has(node.path);
  const indent = folderIndent(depth);

  // Sort children alphabetically
  const sortedChildren = [...node.children].sort((a, b) => a.name.localeCompare(b.name));
  const sortedFiles = [...node.files].sort((a, b) => a.name.localeCompare(b.name));

  return (
    <div className={isExcluded ? 'folder-excluded' : ''}>
      {/* Folder header row */}
      <div
        className="w-full flex items-center gap-1.5 py-1 text-left hover:bg-[var(--hover-bg)] transition-colors group cursor-pointer"
        style={{ paddingLeft: `${indent}px`, paddingRight: '8px' }}
        onClick={() => onToggleExpand(node.path)}
        onContextMenu={(e) => onContextMenu(e, node.path, isExcluded)}
      >
        <span
          className="text-[9px] shrink-0 transition-transform duration-150"
          style={{
            color: 'var(--text-muted)',
            transform: isExpanded ? 'rotate(90deg)' : 'rotate(0deg)',
            display: 'inline-block',
          }}
        >
          {'\u25B6'}
        </span>

        {/* Folder name */}
        <span
          className="flex-1 truncate text-xs"
          style={{
            fontFamily: 'var(--font-jetbrains-mono), monospace',
            fontWeight: depth === 0 ? 600 : 400,
            color: isExcluded
              ? 'var(--text-muted)'
              : depth === 0
                ? 'var(--text)'
                : 'var(--text-muted)',
            letterSpacing: depth === 0 ? '0.01em' : undefined,
          }}
        >
          {node.name}
        </span>

        {/* File count badge */}
        <span className="text-[10px] shrink-0 tabular-nums" style={{ color: 'var(--text-muted)', opacity: 0.6 }}>
          {node.fileCount}
        </span>

        {/* Star button */}
        <button
          className={`star-btn text-[10px] opacity-0 group-hover:opacity-100 ${isFolderStarred ? 'starred opacity-100' : ''}`}
          onClick={(e) => { e.stopPropagation(); onToggleFolderStar(node.path); }}
          title={isFolderStarred ? 'Unstar folder' : 'Star folder'}
        >
          {isFolderStarred ? '\u2605' : '\u2606'}
        </button>

        {/* Remove watch-root button */}
        {isWatchRoot && onRemoveWatchDir && (
          <button
            className="text-[10px] opacity-0 group-hover:opacity-100 px-1.5 py-0.5 rounded transition-opacity"
            style={{ color: '#f87171' }}
            onClick={(e) => { e.stopPropagation(); onRemoveWatchDir(node.path); }}
            title="Stop watching this folder"
          >
            {'\u2715'}
          </button>
        )}
      </div>

      {/* Children -- only when expanded and not excluded */}
      {isExpanded && !isExcluded && (
        <div>
          {sortedChildren.map(child => (
            <FolderGroup
              key={child.path}
              node={child}
              depth={depth + 1}
              selectedPath={selectedPath}
              onSelectFile={onSelectFile}
              onToggleStar={onToggleStar}
              favorites={favorites}
              favoriteFolders={favoriteFolders}
              onToggleFolderStar={onToggleFolderStar}
              expandedGroups={expandedGroups}
              onToggleExpand={onToggleExpand}
              excludedPaths={excludedPaths}
              onContextMenu={onContextMenu}
            />
          ))}
          {sortedFiles.map(file => (
            <FileItem
              key={file.path}
              file={file}
              selected={file.path === selectedPath}
              starred={favorites.has(file.path)}
              onSelect={onSelectFile}
              onToggleStar={onToggleStar}
              indentPx={fileIndent(depth)}
              hideProject
            />
          ))}
        </div>
      )}
    </div>
  );
}

export function FoldersView({
  folders,
  selectedPath,
  onSelectFile,
  onToggleStar,
  favorites,
  favoriteFolders,
  onToggleFolderStar,
  expandedGroups,
  onToggleExpand,
  excludedPaths,
  onExcludeFolder,
  onIncludeFolder,
  customWatchDirs = [],
  onRemoveWatchDir,
}: FoldersViewProps) {
  const [contextMenu, setContextMenu] = useState<ContextMenuState | null>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  const handleContextMenu = useCallback((e: React.MouseEvent, folderPath: string, isExcluded: boolean) => {
    e.preventDefault();
    setContextMenu({ x: e.clientX, y: e.clientY, folderPath, isExcluded });
  }, []);

  useEffect(() => {
    if (!contextMenu) return;
    const handler = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setContextMenu(null);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [contextMenu]);

  if (folders.length === 0) {
    return (
      <div className="p-4 text-center" style={{ color: 'var(--text-muted)' }}>
        <p className="text-sm">No folders found</p>
      </div>
    );
  }

  return (
    <div className="py-1">
      {folders.map(folder => (
        <FolderGroup
          key={folder.path}
          node={folder}
          depth={0}
          selectedPath={selectedPath}
          onSelectFile={onSelectFile}
          onToggleStar={onToggleStar}
          favorites={favorites}
          favoriteFolders={favoriteFolders}
          onToggleFolderStar={onToggleFolderStar}
          expandedGroups={expandedGroups}
          onToggleExpand={onToggleExpand}
          excludedPaths={excludedPaths}
          onContextMenu={handleContextMenu}
          isWatchRoot={customWatchDirs.includes(folder.path)}
          onRemoveWatchDir={onRemoveWatchDir}
        />
      ))}

      {contextMenu && (
        <div ref={menuRef} className="context-menu" style={{ left: contextMenu.x, top: contextMenu.y }}>
          {contextMenu.isExcluded ? (
            <button
              className="context-menu-item"
              onClick={() => { onIncludeFolder(contextMenu.folderPath); setContextMenu(null); }}
            >
              {'\u2713'} Include this folder
            </button>
          ) : (
            <button
              className="context-menu-item destructive"
              onClick={() => { onExcludeFolder(contextMenu.folderPath); setContextMenu(null); }}
            >
              {'\u2715'} Exclude this folder
            </button>
          )}
        </div>
      )}
    </div>
  );
}
