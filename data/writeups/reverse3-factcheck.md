## CTF: picoCTF 2024

Challenge: FactCheck

Category: RE

Difficulty: Intermediate

## Instructions

This binary is putting together some important piece of information... Can you uncover that information?
Examine this file. Do you understand its inner workings?

## Solution

This one test your ability to use a debugger to find the flag after it is made. It's important to know what a dynamic analysis is and why you should use it.

### Dynamic Analysis

Dynamic analysis is the process of running the binary and watching what it does it real time. You usually would use a debugger like gdb or even radare2 has an option to attach a debugger. It's useful to use dynamic analysis when something isn't hardcoded into the binary, but is only made or happens at run time. For example, maybe you're reversing some malware, but you don't see any API calls when you look at it with Ghidra or some static analysis tool. It may be loading those libraries at runtime, meaning to see what it is calling, you have to analyze it while it's actually executing. This is the power of dynamic analysis.

### GDB Basics

Some basic commands for GDB goes as follows.

```bash
b (FUNCTION)
```

This will break at whatever line or symbol you want. This is common to see what might be happening at that line or what registers are filled with.

```bash
disass (FUNCTION)
```

This will show the disassembly of a function, which allows you to read line by line what is going on.

```bash
info func
```

Shows the address of all functions in the binary. Useful if it is not stripped.

My solution is not the best, as it doesn't really have a full understanding of the binary, but more of a guess and check solution. The directions told us the binary is "building something" which I'm assuming means the flag. This means we should be looking for some functions that seem like they are building a string or something similar. Well, this binary makes function calls to a few functions that are clearly making a string. Here are a few of them

```bash
<_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEpLERKS4_@plt>
<_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEpLEc@plt>
<_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEpLERKS4_@plt>
<_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEixEm@plt>
```

These types of function are called a lot and I don't know what they do, but my logic is that if I go to the end of all this, I should see the flag somewhere at some point. I elected to jump to the end of all this string concatenation. After a alot of trial and error, I decided on main+1787. It looks like this.

![image.png](assets/images/writeups/reverse3-factcheck/image.png)

I put a break point there and started looking for the string in all the registers. I found it in rdx, giving me the flag.

## Flag

```bash
academy{wELF_d0N3_mate_9480e1e2}
```

## Mitigation

You should obfuscate you flag as if it's building it in the program, an attacker can just watch and wait to find your secrets.