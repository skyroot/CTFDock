#!/bin/bash

docker run -p 2222:22 --name ctfbox -h ctfbox -v /Users/peleus/Scratch/Docker/:/home/peleus/scratch -t -i -d peleus
