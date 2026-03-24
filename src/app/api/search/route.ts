// GET /api/search?q=...&limit=20 — Full-text content search across all indexed files
// Reads file content from disk and does case-insensitive substring matching.
// Returns SearchResult[] sorted by most recently modified.

import { NextRequest, NextResponse } from 'next/server';
import { readFile } from 'fs/promises';
import { getFileRegistry } from '@/lib/watcher';
import type { SearchResult } from '@/lib/types';

const MAX_FILE_SIZE = 500 * 1024; // Skip files > 500KB
const DEFAULT_LIMIT = 30;
const SNIPPET_CONTEXT = 60; // chars of context on each side of match

function buildSnippet(content: string, query: string, queryLower: string): { snippet: string; lineNumber: number; matchCount: number } {
  const contentLower = content.toLowerCase();
  const firstIdx = contentLower.indexOf(queryLower);
  if (firstIdx === -1) return { snippet: '', lineNumber: 0, matchCount: 0 };

  // Count matches
  let matchCount = 0;
  let searchFrom = 0;
  while (true) {
    const idx = contentLower.indexOf(queryLower, searchFrom);
    if (idx === -1) break;
    matchCount++;
    searchFrom = idx + queryLower.length;
  }

  // Line number of first match
  const lineNumber = content.slice(0, firstIdx).split('\n').length;

  // Build snippet around first match
  const start = Math.max(0, firstIdx - SNIPPET_CONTEXT);
  const end = Math.min(content.length, firstIdx + query.length + SNIPPET_CONTEXT);
  let snippet = content.slice(start, end).replace(/\n/g, ' ').replace(/\s+/g, ' ').trim();
  if (start > 0) snippet = '...' + snippet;
  if (end < content.length) snippet = snippet + '...';

  return { snippet, lineNumber, matchCount };
}

export async function GET(request: NextRequest) {
  const q = request.nextUrl.searchParams.get('q')?.trim();
  const limit = Math.min(
    parseInt(request.nextUrl.searchParams.get('limit') || '', 10) || DEFAULT_LIMIT,
    100
  );

  if (!q || q.length < 2) {
    return NextResponse.json({ results: [], query: q || '' });
  }

  const registry = getFileRegistry();
  const files = Array.from(registry.values())
    .filter(f => f.size <= MAX_FILE_SIZE)
    .sort((a, b) => b.modifiedAt - a.modifiedAt);

  const queryLower = q.toLowerCase();
  const results: SearchResult[] = [];

  // Read files in parallel batches of 50 for speed
  const BATCH_SIZE = 50;
  for (let i = 0; i < files.length && results.length < limit; i += BATCH_SIZE) {
    const batch = files.slice(i, i + BATCH_SIZE);
    const contents = await Promise.allSettled(
      batch.map(f => readFile(f.path, 'utf-8'))
    );

    for (let j = 0; j < batch.length && results.length < limit; j++) {
      const result = contents[j];
      if (result.status !== 'fulfilled') continue;

      const content = result.value;
      if (!content.toLowerCase().includes(queryLower)) continue;

      const { snippet, lineNumber, matchCount } = buildSnippet(content, q, queryLower);
      if (matchCount === 0) continue;

      results.push({
        file: batch[j],
        snippet,
        lineNumber,
        matchCount,
      });
    }
  }

  return NextResponse.json({ results, query: q });
}
