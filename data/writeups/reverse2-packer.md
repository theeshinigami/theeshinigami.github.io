## CTF: picoCTF 2024

Challenge: packer

Category: RE

Difficulty: Intermediate

## Instructions

Reverse this linux executable?

Hint: What can we do to reduce the size of a binary after compiling it.

## Solution

This challenge taught me about packing and unpacking binaries.

### Packing and Unpacking Binaries

Packing makes a binary smaller or harder to read. A packer compresses the program's code and adds a small startup routine. When you run the code, that routine restores the code in memory and the program starts normally. This defeats static analysis and makes dynamic analysis hard since you don't know where the startup routine is and can't set breakpoints properly. The best option is to simply unpack the binary first.

### UPX

UPX ("Ultimate Packer for eXecutables") is the tool for this. Unpack with:

```bash
upx -d <file>
```

Now the binary can be properly analyzed. Looking at the unpacked binary in radare2, you'll see "Password correct" along with suspicious hex. Grab that hex and decode it in CyberChef.

## Flag

```
academy{U9X_UnP4ck1N6_B1n4Ri3S_0fafb2d7}
```

## Mitigation

Make it harder to unpack the file and don't hardcode secrets.
