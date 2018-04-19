#!/bin/bash

docker run -p 2222:22 --name ctfdock -h ctf -v /Users/peleus/Scratch/Docker/:/home/peleus/scratch -t -i -d ctfdock:1.0
