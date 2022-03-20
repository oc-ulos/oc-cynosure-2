# Cynosure 2 system calls

This document lists all the system calls provided by the Cynosure kernel.  System call functions are defined in `src/syscalls.lua`.  If a system call is not described here, consult the appropriate Linux manual page for a rough idea of its behavior.  Most changes are Cynosure representing a value as a string where Linux represents it as a numeric value.

## File-related syscalls

## `open(file, mode): fd`
Arguments:
- **file** *string* The file to open
- **mode** *string* The file mode

Returns:
- **fd** *number* The returned file descriptor

Opens the given file using the given mode, and returns a file descriptor for it.


## `ioctl(fd, operation, ...): ...`
Arguments:
- **fd** *number* The file descriptor on which to operate
- **operation** *string* The operation to perform

The Swiss army knife of Unix-like operating systems.  Performs the requested special operation on the provided file descriptor.

## `read(fd, fmt): data`
Arguments:
- **fd** *number* The file descriptor on which to operate
- **fmt** *number or string* The amount of data to read

Returns:
- **data** *string* The data that was read

Reads some data from the given file descriptor.  `fmt` may be either a string in the same format accepted by `io.read`, or a number of bytes to read.

## `write(fd, data)`
Arguments
- **fd** *number* The file descriptor on which to operate
- **data** *string* The data to write

Writes some data to the given file descriptor.

## `seek(fd, whence, offset)`
## `flush(fd)`
## `opendir(file)`
## `readdir(fd)`
## `close(fd)`
## `mkdir(path)`
## `stat(path)`
## `link(source, dest)`
## `unlink(path)`
## `mount(node, path)`
## `unmount(path)`

## Process-related syscalls

## `fork(func)`
## `execve(path, args, env)`
## `wait(pid)`
## `exit(status)`
## `getcwd()`
## `chdir(path)`
## `setuid(uid)`
## `seteuid(uid)`
## `getuid()`
## `geteuid()`
## `setgid(uid)`
## `setegid(uid)`
## `getgid()`
## `getegid()`
## `setsid()`
## `getsid()`
## `setpgrp(pid, pg)`
## `getpgrp(pid)`
## `sigaction(name, handler)`
## `kill(pid, name)`

## Miscellaneous syscalls

## `reboot(cmd)`
