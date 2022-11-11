#!/usr/bin/env lua
-- dynamically generate UPT build config for Cynosure 2

os.execute("lua scripts/preproc.lua uptbuild.skelconf uptbuild.conf")
