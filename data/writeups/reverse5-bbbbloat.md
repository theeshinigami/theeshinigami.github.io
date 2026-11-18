## CTF: picoCTF2022

Challenge: Bbbbloat

Category: RE

Difficulty: Intermediate

## Instructions

Can you get the flag?
Reverse engineer this binary.

## Solution

This is a nice start to getting back into the flow of reverse engineering, so lets get into it. For me, learning what radare2 is and what some common commands you need to run. I would also say I tried to cheat and use gef, but since the binary was both stripped and had PIE enabled, I was forced to actually read the disassembly which is great practice.

### What is Radare2

Radare2 is a reverse engineering tool used to disaseemble,debug, and patch binary files. Some common uses of it are Malware Triage, Vulnerability Research and even some binary patching which can be used to get pass cheat engines

### Common Commands

```bash
[0x00001307]> aaa
INFO: Analyze all flags starting with sym. and entry0 (aa)
INFO: Analyze imports (af@@@i)
INFO: Analyze entrypoint (af@ entry0)
INFO: Analyze symbols (af@@@s)
INFO: Analyze all functions arguments/locals (afva@@F)
INFO: Analyze function calls (aac)
INFO: Analyze len bytes of instructions for references (aar)
INFO: Finding and parsing C++ vtables (avrr)
INFO: Analyzing methods (af @@ method.*)
INFO: Recovering local variables (afva@@@F)
INFO: Type matching analysis for all functions (aaft)
INFO: Propagate noreturn information (aanr)
INFO: Use -AA or aaaa to perform additional experimental analysis

```

**aaa** is used to automatically analyze all of the code in the binary. It runs other commands under the hood, but it is essential to run before you start doing any debugging.

```bash
[0x00001160]> s main
```

**s main** is used to go to main to see what it is doing and start debugging form there.

```bash
[0x00001307]> pdf
```

**pdf** is used to print the disassembly for the current function you are in, so you can start looking at the disassembly and get hacking.

So to start, I always like running the **file** command and running the actual executable to see what I need to find. Make sure to make the binary executable to actually run it with **chmod**

![image.png](assets/images/writeups/reverse5-bbbbloat/image.png)

As we can see, PIE is enabled, and it's stripped as well. This would make any dynamic analysis a pain in my side, so using a reverse engineering tool like radare2 or ghidra would be ideal. We can also see that we are looking for the "favorite number". My mind immediately goes to finding a cmp to a hardcoded number and then whether it jumps or not. Luckily radare2 makes it very easy to visualize this. I simply ran radare2, analyzed it with aaa, went to main and typed in pdf, and then found the following instructions indicated in the screenshot.

```bash
[0x00001307]> aaa
[0x00001160]> s main
[0x00001307]> pdf

```

![image.png](assets/images/writeups/reverse5-bbbbloat/image-1.png)

This is what we are looking for, we can see that it is comparing with the hex value 0x86187. We also can see that if it evaluates to true, we would go to the "sorry that's not right" and exit the function, but if we put the correct number, it continues with the logic to print the flag as shown below.

Logic to print flag:

![image.png](assets/images/writeups/reverse5-bbbbloat/image-2.png)

Logic if the number is wrong:

![image.png](assets/images/writeups/reverse5-bbbbloat/image-3.png)

So to solve this problem, you just need to type in the correct number. Translating hex to decimal, you get the number 549255. Typing that in when you run the program gives you the correct flag.

![image.png](assets/images/writeups/reverse5-bbbbloat/image-4.png)

## Flag

```bash
academy{cu7_7h3_bl047_d67f6a67}
```

## Mitigation

Don't hardcode secrets, obfuscate them so attackers can't find it