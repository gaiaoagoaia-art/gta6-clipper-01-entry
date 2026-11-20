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

// ---------------------------------------------------------------------------
// Clip verification (added in a later revision, after the first grading run
// showed main.ts had only ever been written once): when the rendered clip
// is on disk, check it against the competition spec with ffprobe before
// anyone trusts it. build-clip.sh renders the clip into the repo's parent
// directory (../gta6-clipper-01-clip.mp4 — kept out of git for its size),
// so that is where this section looks; MAKEFUN_CLIP_PATH overrides it.
// The grader's sandbox holds only the repo, so a missing clip is reported
// and skipped, never failed. A clip that IS present must pass every
// assertion below or this program exits non-zero.
// ---------------------------------------------------------------------------

import { execFileSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';

interface ProbeStream {
  codec_type?: string;
  width?: number;
  height?: number;
  avg_frame_rate?: string;
  r_frame_rate?: string;
}

interface ProbeResult {
  streams?: ProbeStream[];
  format?: { duration?: string };
}

const clipPath =
  process.env.MAKEFUN_CLIP_PATH ?? resolve(join(botDir, '..', 'gta6-clipper-01-clip.mp4'));

if (!existsSync(clipPath)) {
  console.log(`clip verification: no clip at ${clipPath} — skipped (nothing rendered here)`);
} else {
  let probe: ProbeResult | null = null;
  try {
    const raw = execFileSync(
      'ffprobe',
      [
        '-v', 'error',
        '-show_entries', 'stream=codec_type,width,height,avg_frame_rate,r_frame_rate',
        '-show_entries', 'format=duration',
        '-of', 'json',
        clipPath,
      ],
      { encoding: 'utf8' },
    );
    probe = JSON.parse(raw) as ProbeResult;
  } catch (err) {
    console.error(`clip verification: FAIL — ffprobe could not read ${clipPath}: ${(err as Error).message}`);
    process.exit(1);
  }

  const streams = probe.streams ?? [];
  const video = streams.find((s) => s.codec_type === 'video');
  const audio = streams.find((s) => s.codec_type === 'audio');
  const duration = Number.parseFloat(probe.format?.duration ?? 'NaN');

  const rateParts = (video?.avg_frame_rate ?? video?.r_frame_rate ?? '0/1').split('/');
  const fps = Number(rateParts[1]) ? Number(rateParts[0]) / Number(rateParts[1]) : 0;

  const assertions: Array<[string, boolean, string]> = [
    ['video stream present', video !== undefined, video ? 'found' : 'missing'],
    ['width is 1080', video?.width === 1080, `got ${video?.width ?? 'n/a'}`],
    ['height is 1920', video?.height === 1920, `got ${video?.height ?? 'n/a'}`],
    [
      'duration between 30s and 45s',
      Number.isFinite(duration) && duration >= 30 && duration <= 45,
      `got ${Number.isFinite(duration) ? duration.toFixed(2) : 'n/a'}s`,
    ],
    ['frame rate ~30fps', fps >= 29 && fps <= 31, `got ${fps ? fps.toFixed(2) : 'n/a'}fps`],
    ['audio stream present', audio !== undefined, audio ? 'found' : 'missing'],
  ];

  let failures = 0;
  for (const [name, ok, detail] of assertions) {
    console.log(`clip check — ${name}: ${ok ? 'PASS' : 'FAIL'} (${detail})`);
    if (!ok) failures += 1;
  }
  console.log(
    `clip verification: ${assertions.length - failures}/${assertions.length} assertions passed for ${clipPath}`,
  );
  if (failures > 0) {
    console.error('clip verification: FAIL — the rendered clip is outside the competition spec');
    process.exit(1);
  }
}
