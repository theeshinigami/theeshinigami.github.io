## CTF: picoCTF 2024

Challenge: Bit-O-Asm-4

Category: RE

Difficulty: Intermediate

## Instructions

Can you figure out what is in the eax register? Put your answer in the picoCTF flag format: picoCTF{n} where n is the contents of the eax register in the decimal number base.

## Solution

This is a good challenge to walk through assembly line by line. Good practice for reverse engineering as a whole.

```asm
<+0>:     endbr64
<+4>:     push   rbp
<+5>:     mov    rbp,rsp
<+8>:     mov    DWORD PTR [rbp-0x14],edi
<+11>:    mov    QWORD PTR [rbp-0x20],rsi
<+15>:    mov    DWORD PTR [rbp-0x4],0x9fe1a
<+22>:    cmp    DWORD PTR [rbp-0x4],0x2710
<+29>:    jle    0x55555555514e <main+37>
<+31>:    sub    DWORD PTR [rbp-0x4],0x65
<+35>:    jmp    0x555555555152 <main+41>
<+37>:    add    DWORD PTR [rbp-0x4],0x65
<+41>:    mov    eax,DWORD PTR [rbp-0x4]
<+44>:    pop    rbp
<+45>:    ret
```

Walking through it:

- `endbr64` — protection against ROP (not relevant here)
- `push rbp` / `mov rbp,rsp` — function prologue
- Move 0x9fe1a into [rbp-0x4]
- Compare with 0x2710. Since 0x9fe1a > 0x2710, the result is positive so we do NOT jump (jle fails)
- At main+31, subtract 0x65 from [rbp-0x4]: `0x9fe1a - 0x65`
- Unconditional jump to main+41, skipping the add instruction
- Move the result into eax

To break it down simply, the answer is `0x9fe1a - 0x65` in decimal = **654773**.

## Flag

```
academy{654773}
```

## Mitigation

Don't make the problem so easy. Longer and harder problems make it harder for attackers to reverse.
