# CYX: the CYnosure eXecutable

The header for every CYX file is as follows:
```c
struct header {
  uint32_t magic = 0x43769e6f;
  uint8_t  version; // should be 0
  uint8_t  flags;
  uint8_t  osid;
  uint8_t  nlink;
}
```

Supported flags:
| Bit    | Name          | Meaning                               |
| :----- | :-----------  | :------------------------------------ |
| `0x1`  | `CYX_LUA53`   | Executable requires Lua 5.3           |
| `0x2`  | `CEX_STATIC`  | Statically linked                     |
| `0x4`  | `CEX_BOOT`    | Executable is bootable (e.g. kernel)  |
| `0x8`  | `CEX_EXEC`    | File can be executed as a program     |
| `0x10` | `CEX_LIBRARY` | File is a library (can be linked to)  |
| `0x20` | `CEX_BIGEND`  | Numbers are big-endian                |
| `0x40` | `CEX_NOINTERP`| File has no interpreter               |
| `0x80` | unused        | This flag has no use                  |

The `link` structure occurs for every link in the file, directly after the header.  If flag `CYX_NOINTERP` is unset, the first link in the file is an absolute path to the interpreter.
```c
struct link {
  char nlen;
  char name[nlen];
}
```

Supported OSIDs are as specified in [this document from OpenStandards](https://globalempire.github.io/OpenStandards/OS/OSID).

After the header and linking information is the file data.  This takes up the rest of the executable.

For statically linked executables, the data of all linked libraries should be contained in `load` statements;  e.g. to statically link the `example` library, the linker should insert the following code:
```lua
local example = assert(load([======[ <data from example.cyx> ]======]))
```
The value of `nlink` should also be `0`;  if it is not, the executable is invalid.

For dynamically linked libraries, the interpreter can either do the above at runtime, or insert a variable with the same name into the loaded code's environment:
```lua
programenv.example = assert(load_cyx("example.cyx"))
```
