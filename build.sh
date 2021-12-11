#!/bin/bash
# build Cynosure 2.0

preproc=utils/preproc.lua
env $(cat .buildconfig) $preproc src/main.lua kernel.lua -strip-comments
