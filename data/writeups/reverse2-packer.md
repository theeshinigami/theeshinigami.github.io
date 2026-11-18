## CTF: picoCTF 2024

Challenge: packer

Category: RE

Difficulty: Intermediate

## Instructions

Reverse this linux executable?

Hint: What can we do to reduce the size of a binary after compiling it.

## Solution

This challenge taught me a new concept I never knew before so lets get to it. Lets start on what packing and unpacking is and why you might do it. We will then get into the solution, which is simple once that unpacking is done.

### Packing and Unpacking Binaries

Packing a binary is making a binary smaller so that it is smaller or harder to read. A developer may do this to reduce the size of their file or protect their code. A packer changes a programs code into a compressed form, that adds a small startup routine. When you run the code, that routine restores the code in memory and the program starts normally. This beats static analysis and makes dynamic analysis hard as since you don't know where this startup routine is, you can't set breakpoints properly. This means the best option is to simply unpack the binary yourself first with upx.

### UPX

UPX ("Ultimate Packer for eXecutables") is a tool that packs and unpacks executable files. It is what adds a small routine that restores the program when ran, and is what is needed to solve this problem

You first need to run upx on the file so you can properly analyze it. Below is the syntax for the command you need to run.

```bash
upx -d <file>
```

Now you can properly analyze the file without it being scrambled. Taking a look at the file, you will see something that says "Password correct" along with some suspicious hex next to it.

![image.png](assets/images/writeups/reverse2-packer/image.png)

You can grab that hex and decode it in cyberchef and sure enough, it is the flag.

## Flag

```bash
academy{U9X_UnP4ck1N6_B1n4Ri3S_0fafb2d7}
```

## Mitigation

Make it so it isn't as easy to unpack the file and don't hardcode secrets.