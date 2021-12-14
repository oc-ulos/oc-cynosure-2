CYNOSURE 2.0
============

This is the second major release of Cynosure.  Much of it has been rewritten, providing a more POSIX-like experience all around.  However, it maintains the same goals of speed, stability, and completeness.

Cynosure 2.0 is not designed to be lightweight on memory.

EXECUTABLES
===========

One major change in Cynosure 2.0 is support for a custom `cyx` executable format.  This format allows both static and dynamic linking of libraries into programs.  See `docs/cyx.txt` for the format specification.  Lua scripts may still be executed if they begin with a shebang.
