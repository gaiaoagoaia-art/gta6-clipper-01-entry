// gta6-clipper-01 entry program (Node 22, standard library only).
//
// The entry is the video itself: an agent-cut vertical GTA 6 clip, posted
// public on YouTube as a Short, whose address lives in VIDEO.json at this
// repository's root. All this program does is copy that file to the
// grader's output directory, where the gate reads it and the house's own
// YouTube counts decide the places. Nothing this program writes about the
// video is scored.
//
// VIDEO.json currently holds a placeholder (an empty url). It is replaced
// with the uploaded video's address before the entry is submitted.
//
// Run it the way the grader does:
//   mkdir -p out && MAKEFUN_BOT_DIR=. MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';

const botDir = process.env.MAKEFUN_BOT_DIR ?? '/bot';
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

mkdirSync(outputDir, { recursive: true });

const source = join(botDir, 'VIDEO.json');
const target = join(outputDir, 'VIDEO.json');

try {
  copyFileSync(source, target);
} catch (err) {
  console.error(`Could not copy VIDEO.json from ${source}: ${(err as Error).message}`);
  process.exit(1);
}
