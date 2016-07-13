#!/bin/bash

# radarsim -v --concept DBU -T -p 2400 -t 0.001 -D 100 -O ~/Downloads/anim -o
# radarsim -v --concept DBU -T -p 4800 -t 0.0005 --sweep P:-12:12:0.005 -D 100 -O ~/Downloads/anim -o
# radarsim -v --concept DBU -T -p 4800 -t 0.0005 --sweep P:-12:12:0.005 -D 100 -O ~/Downloads/anim -d 20000 -o
# radarsim -v --concept DBU -T -p 4800 -t 0.0005 --sweep P:-12:12:0.005 -D 100 -O ~/Downloads/anim -d 200000 -o
# radarsim -v --concept DBU -T -p 4800 -t 0.0005 --sweep P:-12:12:0.005 -D 141 -O ~/Downloads/anim -d 400000 -o
# radarsim -v --concept DBU -T -p 4800 -t 0.0005 --sweep P:-12:12:0.005 -D 230 -O ~/Downloads/anim -d 800000 -o
# radarsim -v --concept DBU -T -p 4800 -t 0.0005 --sweep P:-12:12:0.005 -D 410 -O ~/Downloads/anim -d 1600000 -o
# radarsim -v --concept DBU -T -p 4800 -t 0.0005 --sweep P:-12:12:0.005 -D 770 -O ~/Downloads/anim -d 3200000 -o
# 
# radarsim -v --concept DBU -T -p 633600 -t 0.0005 --sweep P:-12:12:0.005 -D 100 -O ~/Downloads/anim -o
# radarsim -v --concept DBU -T -p 633600 -t 0.0005 --sweep P:-12:12:0.005 -D 410 -O ~/Downloads/anim -d 1600000 -o
# 
# radarsim -v --concept DBU -T -p 2400 -t 0.001 -D 100 -O ~/Downloads/simradar -o
# radarsim -v --concept DBU -T -p 4800 -t 0.0005 --sweep P:-12:12:0.005 -D 100 -O ~/Downloads/simradar -o
# radarsim -v --concept DBU -T -p 4800 -t 0.0005 --sweep P:-12:12:0.005 -D 100 -O ~/Downloads/simradar -d 20000 -o
# radarsim -v --concept DBU -T -p 4800 -t 0.0005 --sweep P:-12:12:0.005 -D 100 -O ~/Downloads/simradar -d 200000 -o
# radarsim -v --concept DBU -T -p 4800 -t 0.0005 --sweep P:-12:12:0.005 -D 100 -O ~/Downloads/simradar -d 400000 -o
# radarsim -v --concept DBU -T -p 4800 -t 0.0005 --sweep P:-12:12:0.005 -D 100 -O ~/Downloads/simradar -d 800000 -o
# radarsim -v --concept DBU -T -p 4800 -t 0.0005 --sweep P:-12:12:0.005 -D 100 -O ~/Downloads/simradar -d 1600000 -o

# radarsim -v --concept DBU -T -p 633600 -t 0.0005 --sweep P:-12:12:0.005 -D 100 -O ~/Downloads/simradar -o
# radarsim -v --concept DBU -T -p 633600 -t 0.0005 --sweep P:-12:12:0.005 -D 100 -O ~/Downloads/simradar -d 1600000 -o

# Superposition test
# 1. Weather only
# 2. Debris only (transparent background)
# 3. Weather + debris

# radarsim -v --concept DBU  -T -p 2400 -t 0.0005 --sweep P:-12:12:0.01 -D 100 -O ~/Downloads/simradar -o
# radarsim -v --concept DBUT -T -p 2400 -t 0.0005 --sweep P:-12:12:0.01 -D 100 -O ~/Downloads/simradar -d 200000 -o
# radarsim -v --concept DBU  -T -p 2400 -t 0.0005 --sweep P:-12:12:0.01 -D 100 -O ~/Downloads/simradar -d 200000 -o

# Validation
# radarsim -vvv --concept DBU  -T -p 100 -t 0.0005 --sweep P:-12:12:0.01 -D 100 -O ~/Downloads/simradar -o > test_wx.txt
# radarsim -vvv --concept DBUT -T -p 100 -t 0.0005 --sweep P:-12:12:0.01 -D 100 -O ~/Downloads/simradar -d 2000 -o > test_db.txt
# radarsim -vvv --concept DBU  -T -p 100 -t 0.0005 --sweep P:-12:12:0.01 -D 100 -O ~/Downloads/simradar -d 2000 -o > test_wxdb.txt
# radarsim --concept DBU  -T -p 1000 -t 0.0005 --sweep P:-12:12:0.01 -D 100 -O ~/Downloads/simradar -o
# radarsim --concept DBUT -T -p 1000 -t 0.0005 --sweep P:-12:12:0.01 -D 100 -O ~/Downloads/simradar -d 2000 -o
# radarsim --concept DBU  -T -p 1000 -t 0.0005 --sweep P:-12:12:0.01 -D 100 -O ~/Downloads/simradar -d 2000 -o

rm -f ~/Downloads/simradar/*.iq
radarsim -vvv --concept DBUT -T -p 5 -t 0.0005 --sweep P:-12:12:0.01 -D 100 -O ~/Downloads/simradar -d 2000 -W 1000 > ~/Downloads/simradar/test_db.txt
radarsim -vvv --concept DBU  -T -p 5 -t 0.0005 --sweep P:-12:12:0.01 -D 100 -O ~/Downloads/simradar -d 2000 -W 1000 > ~/Downloads/simradar/test_wxdb.txt
