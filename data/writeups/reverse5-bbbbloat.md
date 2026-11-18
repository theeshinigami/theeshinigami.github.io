## CTF: picoCTF 2022

Challenge: Bbbbloat

Category: RE

Difficulty: Intermediate

## Instructions

Can you get the flag? Reverse engineer this binary.

## Solution

This is a nice start to getting back into the flow of reverse engineering. For me, learning radare2 and its common commands was key. I tried to cheat and use gef, but since the binary was both stripped and had PIE enabled, I was forced to actually read the disassembly — great practice.

### What is Radare2

Radare2 is a reverse engineering tool used to disassemble, debug, and patch binary files. Common uses include Malware Triage, Vulnerability Research, and binary patching.

### Common Commands

```bash
aaa    # Automatically analyze all code in the binary
s main # Seek to main function
pdf    # Print disassembly for current function
```

Running `file` shows PIE is enabled and it's stripped. We're looking for the "favorite number". My approach: find a `cmp` to a hardcoded number and check the branch.

In radare2:

```bash
[0x00001307]> aaa
[0x00001160]> s main
[0x00001307]> pdf
```

Found a comparison with hex value `0x86187`. If it evaluates to true (wrong number), it goes to "sorry that's not right". Otherwise it prints the flag.

Converting `0x86187` to decimal gives **549255**. Typing that in gives the flag.

## Flag

```
academy{cu7_7h3_bl047_d67f6a67}
```

## Mitigation

Don't hardcode secrets, obfuscate them so attackers can't find them.
