#!/bin/bash
# build Cynosure 2.0

preproc=utils/preproc.lua
$preproc src/main.lua kernel.lua
