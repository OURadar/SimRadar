#!/bin/bash

gource -1280x720 --logo logo.png --seconds-per-day 0.15 --hide filenames,progress,mouse --user-image-dir ~/Pictures/Avatar/ -o - | ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -crf 1 -threads 4 -bf 0 gource-simradar-$(date '+%Y-%m-%d').mp4

