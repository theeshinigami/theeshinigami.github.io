## CTF: picoCTF 2024

Challenge: FactCheck

Category: RE

Difficulty: Intermediate

## Instructions

This binary is putting together some important piece of information... Can you uncover that information?

## Solution

This one tests your ability to use a debugger to find the flag after it is made at runtime.

### Dynamic Analysis

Dynamic analysis is the process of running the binary and watching what it does in real time. Use a debugger like gdb or radare2. It's useful when something isn't hardcoded into the binary but is only made at runtime — for example, malware loading libraries dynamically.

### GDB Basics

```bash
b (FUNCTION)       # Set breakpoint at function or line
disass (FUNCTION)  # Show disassembly of a function
info func          # Show all function addresses
```

The directions said the binary is "building something" — the flag. The binary makes calls to C++ string concatenation functions:

```
<_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEpLERKS4_@plt>
<_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEpLEc@plt>
```

My solution isn't the most elegant — it's more guess and check. The idea: jump to the end of all this string concatenation. After a lot of trial and error, I set a breakpoint at main+1787 and examined the registers. Found the flag in rdx.

## Flag

```
academy{wELF_d0N3_mate_9480e1e2}
```

## Mitigation

Obfuscate your flag if the program builds it — an attacker can just watch and wait to find your secrets.
