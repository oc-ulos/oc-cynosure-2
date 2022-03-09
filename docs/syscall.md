# Userspace system calls

Making a system call from user space is done through yielding, e.g:

    coroutine.yield("syscall", "open", "file:///bin/ls")

Userspace should provide wrappers around this facility.

The first return value of the system call will be either its result or 
