# Cynosure 2 system calls

## `open(file, mode): fd`
Arguments:
- **file** *string* The file to open
- **mode** *string* The file mode

Returns:
- *fd* The returned file descriptor

Opens the given file using the given mode, and returns a file descriptor for it.


## `ioctl(fd, operation, ...): ...`
Arguments:
- **fd** *number* The file descriptor on which to operate
- **operation** *string* The operation to perform
