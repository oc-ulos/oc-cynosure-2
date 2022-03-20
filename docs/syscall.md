# Userspace system calls

Making a system call from user space is done through yielding, e.g:

    coroutine.yield("syscall", "open", "/bin/ls")

Userspace should provide wrappers around this facility.

The first return value of the system call will be either its result or `nil`.  If it is `nil` then the second return value will be either an `errno` value or a string describing the error.  If it is a string, userspace wrappers should raise an error.
