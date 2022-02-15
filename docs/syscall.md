# Userspace system calls

Making a system call from user space is done through yielding, e.g:

    coroutine.yield("syscall", "open", "file:///bin/ls")

Userspace should provide convenient wrappers around this facility.
