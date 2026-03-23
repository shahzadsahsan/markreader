// GET /api/files?view=recents|folders|favorites|history
// Returns the file list for the requested sidebar view.

import { NextRequest, NextResponse } from 'next/server';
import { getFilesForView, getFileRegistry, isScanComplete, getWatchedDirs } from '@/lib/watcher';
import { getFavorites, getHistory } from '@/lib/state';
import type { FileEntry, FolderNode } from '@/lib/types';
import os from 'os';
import path from 'path';

/**
 * Build a true directory tree rooted at each watch dir.
 * Each node's `path` is the full absolute filesystem path,
 * so the Remove button and other path comparisons work correctly.
 */
function buildFolderTree(files: FileEntry[], watchedDirs: string[]): FolderNode[] {
  const homeDir = os.homedir();
  const nodeMap = new Map<string, FolderNode>();

  // Create root nodes for each watched directory
  for (const dir of watchedDirs) {
    const displayName = dir.startsWith(homeDir)
      ? '~' + dir.slice(homeDir.length)
      : dir;
    nodeMap.set(dir, { name: displayName, path: dir, files: [], children: [], fileCount: 0 });
  }

  for (const file of files) {
    // Find the deepest watch dir that contains this file
    const watchDir = watchedDirs
      .filter(d => file.path.startsWith(d + path.sep) || file.path.startsWith(d + '/'))
      .sort((a, b) => b.length - a.length)[0];
    if (!watchDir) continue;

    const rel = file.path.slice(watchDir.length + 1);
    const parts = rel.split('/');

    let currentPath = watchDir;
    let currentNode = nodeMap.get(watchDir)!;
    currentNode.fileCount++;

    // Walk/create intermediate directory nodes
    for (let i = 0; i < parts.length - 1; i++) {
      const childPath = currentPath + '/' + parts[i];
      if (!nodeMap.has(childPath)) {
        const child: FolderNode = {
          name: parts[i],
          path: childPath,
          files: [],
          children: [],
          fileCount: 0,
        };
        nodeMap.set(childPath, child);
        currentNode.children.push(child);
      }
      const child = nodeMap.get(childPath)!;
      child.fileCount++;
      currentPath = childPath;
      currentNode = child;
    }

    currentNode.files.push(file);
  }

  // Return only roots that have content
  return watchedDirs
    .map(d => nodeMap.get(d))
    .filter((n): n is FolderNode => n !== undefined && n.fileCount > 0)
    .sort((a, b) => a.name.localeCompare(b.name));
}

export async function GET(request: NextRequest) {
  const view = request.nextUrl.searchParams.get('view') || 'recents';

  const response: {
    files?: FileEntry[];
    folders?: FolderNode[];
    scanComplete: boolean;
    totalFiles: number;
  } = {
    scanComplete: isScanComplete(),
    totalFiles: getFileRegistry().size,
  };

  switch (view) {
    case 'recents':
      response.files = getFilesForView('recents');
      break;

    case 'folders':
      response.folders = buildFolderTree(getFilesForView('folders'), getWatchedDirs());
      break;

    case 'favorites': {
      const favorites = await getFavorites();
      const registry = getFileRegistry();
      response.files = favorites
        .map(f => registry.get(f.path))
        .filter((f): f is FileEntry => f !== undefined);
      break;
    }

    case 'history': {
      const history = await getHistory();
      const registry = getFileRegistry();
      response.files = history
        .map(h => {
          const entry = registry.get(h.path);
          if (!entry) return null;
          return { ...entry, lastOpenedAt: h.lastOpenedAt };
        })
        .filter((f): f is FileEntry & { lastOpenedAt: number } => f !== null);
      break;
    }

    default:
      response.files = getFilesForView('recents');
  }

  return NextResponse.json(response);
}
