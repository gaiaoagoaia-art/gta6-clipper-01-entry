#!/usr/bin/env bash
# build-clip.sh — renders the gta6-clipper-01 entry clip from Rockstar's
# official "Grand Theft Auto VI Launch Trailer".
#
# Creative decisions (made by the agent in the session that runs this):
# - Source: https://www.youtube.com/watch?v=rz1B4B2yBZY (Rockstar Games,
#   "Grand Theft Auto VI Launch Trailer", 90 s, 1920x1080, downloaded with
#   yt-dlp at 1080p). The age-restricted 26-minute "An Extended Look"
#   gameplay showcase could not be fetched from this machine (no signed-in
#   YouTube session here), so the Launch Trailer — the newest official
#   footage, released 15 Oct 2026 for the 19 Nov 2026 launch — is the source.
# - Moment used: 00:46-01:12 of the trailer, one continuous action run:
#   red sports car speeding, police car drifting, a motorcycle ramping off
#   a ledge and hanging mid-air, Jason at night with an explosion behind
#   him, a plane trailing pink smoke over a packed Vice City beach. The
#   motorcycle jump (~00:49) is the hook: a single frame that reads
#   instantly even at thumbnail size, and it opens the clip's first
#   2 seconds.
# - Shape: 26 s of that action run, then an 8 s pitch end card built on a
#   dimmed freeze of the jump frame, so the clip ends on its best image.
#   Total 34 s, vertical 1080x1920, 30 fps — a YouTube Short.
# - Vertical framing: blur-fill (the same frame blurred behind, the sharp
#   frame centred) so nothing of the 16:9 shot is cropped away.
# - Captions (DejaVu Sans Bold, white with a black border, burned in):
#   "GTA 6 IS HERE" over the opening car shots, "INSANE STUNT" over the
#   jump, "VICE CITY IS ALIVE" over the beach plane, "JASON & LUCIA"
#   over the sunset embrace.
# - Pitch (end card, on screen long enough to read): "MAKE CLIPS LIKE
#   THIS WITH AI AND EARN MONEY ON MAKE.FUN" plus the bounty page
#   "make.fun/bounty/gta6-clipper-01".
# - Audio: the trailer's own soundtrack, loudness-normalised to -14 LUFS.
#
# Usage: run from the directory holding launch-trailer.mp4 (the work dir).
# Output: ../gta6-clipper-01-clip.mp4 (kept OUT of the git repo: file size).
set -euo pipefail

SRC="${SRC:-launch-trailer.mp4}"
OUT="${OUT:-../gta6-clipper-01-clip.mp4}"
FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf

# Shared vertical treatment: blur-fill the 16:9 frame into 1080x1920.
VFILL="split=2[bg][fg];[bg]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,gblur=sigma=40[bg];[fg]scale=1080:-1[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2"

# 1. Gameplay body: trailer 00:46-01:12 (26 s) with hook + light captions.
ffmpeg -y -v error -ss 46 -t 26 -i "$SRC" -filter_complex \
  "[0:v]$VFILL,drawtext=fontfile=$FONT:text='GTA 6 IS HERE':fontsize=88:fontcolor=white:borderw=4:bordercolor=black:x=(w-text_w)/2:y=300:enable='between(t,0.5,3)',drawtext=fontfile=$FONT:text='INSANE STUNT':fontsize=80:fontcolor=white:borderw=4:bordercolor=black:x=(w-text_w)/2:y=300:enable='between(t,3,5.5)',drawtext=fontfile=$FONT:text='VICE CITY IS ALIVE':fontsize=72:fontcolor=white:borderw=4:bordercolor=black:x=(w-text_w)/2:y=300:enable='between(t,9,12)',drawtext=fontfile=$FONT:text='JASON & LUCIA':fontsize=80:fontcolor=white:borderw=4:bordercolor=black:x=(w-text_w)/2:y=300:enable='between(t,20,23)'[v];[0:a]loudnorm=I=-14:TP=-1.5:LRA=11[a]" \
  -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 20 -r 30 \
  -c:a aac -b:a 160k gameplay.mp4

# 2. Pitch end card: 8 s on a dimmed freeze of the jump frame (~00:49.5),
#    audio from the trailer's 01:12-01:20, faded out.
ffmpeg -y -v error -ss 49.5 -i "$SRC" -frames:v 1 jump.png
ffmpeg -y -v error -loop 1 -t 8 -i jump.png -ss 72 -t 8 -i "$SRC" -filter_complex \
  "[0:v]$VFILL,eq=brightness=-0.45:saturation=0.7,drawtext=fontfile=$FONT:text='MAKE CLIPS LIKE THIS':fontsize=64:fontcolor=white:borderw=4:bordercolor=black:x=(w-text_w)/2:y=700,drawtext=fontfile=$FONT:text='WITH AI AND EARN MONEY':fontsize=64:fontcolor=white:borderw=4:bordercolor=black:x=(w-text_w)/2:y=800,drawtext=fontfile=$FONT:text='ON MAKE.FUN':fontsize=64:fontcolor=white:borderw=4:bordercolor=black:x=(w-text_w)/2:y=900,drawtext=fontfile=$FONT:text='make.fun/bounty/gta6-clipper-01':fontsize=46:fontcolor=#ffd166:borderw=3:bordercolor=black:x=(w-text_w)/2:y=1060[v];[1:a]afade=t=out:st=6:d=2,loudnorm=I=-14:TP=-1.5:LRA=11[a]" \
  -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 20 -r 30 \
  -c:a aac -b:a 160k endcard.mp4

# 3. Join body + end card into the final clip.
ffmpeg -y -v error -i gameplay.mp4 -i endcard.mp4 -filter_complex \
  "[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[v][a]" \
  -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 20 \
  -c:a aac -b:a 160k "$OUT"

ffprobe -v error -show_entries format=duration,size \
  -show_entries stream=width,height,r_frame_rate,codec_name -of default=nw=1 "$OUT"
echo "WROTE $OUT"
