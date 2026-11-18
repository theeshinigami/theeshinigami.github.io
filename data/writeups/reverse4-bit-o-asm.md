## CTF: picoCTF2024

Challenge: Bit-O-Asm-4

Category: RE

Difficulty:  Intermediate

## Instructions

Can you figure out what is in the eax register? Put your answer in the picoCTF flag format: picoCTF{n} where n is the contents of the eax register in the decimal number base. If the answer was 0x11 your flag would be picoCTF{17}.
Download the assembly dump here.

Hints:

1. Don't tell anyone I told you this, but you can solve this problem without understanding the compare/jump relationship.
2. Of course, if you're really good, you'll only need one attempt to solve this problem.

## Solution

This is a good challenge to walk through assembly line by line. Good practice for reverse engineering as a whole, so lets go over it.

```bash
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

The first line acts for a protection against Return Oriented Programming which is out of scope for reversing this binary, but is important for binary exploitation. Just know that it is needed to guard against exploits.

Push rbp and mov rbp,rsp acts as the program prolouge. It pushes rbp of the old function so that when you start to exit the program, you know where the function that called this ones base pointer is. You then point rbp and rsp to the same point. The next two lines you move edi and rsi on to the stack. These registers would hold the value of whatever arguments were passed to this function before it was called. Again not terribly important for this challenge but good to know. This next instruction is the first important one.

```bash
<+15>:    mov    DWORD PTR [rbp-0x4],0x9fe1a
<+22>:    cmp    DWORD PTR [rbp-0x4],0x2710
<+29>:    jle    0x55555555514e <main+37>

```

You are going to move the value 0x9fe1a into rbp-0x4 and then compare it with the value 0x2710. Essentially, you'll perform the operation 0x9fe1a - 0x2710. If the number is less than or equal to zero, you will jump to main+37. If it is not, you will continue on. In this case, it is not, so we will keep going along.

```bash
<+31>:    sub    DWORD PTR [rbp-0x4],0x65
<+35>:    jmp    0x555555555152 <main+41>
<+37>:    add    DWORD PTR [rbp-0x4],0x65
<+41>:    mov    eax,DWORD PTR [rbp-0x4]
```

At main+31, you will subtract from whatever is in rbp-0x4 (which is 0x9fe1a) the value 0x65 from it. You will essentially perform 0x9fe1a - 0x65 and put it back into rbp-0x4. At main+35, you will perform an unconditional jump, going pass the add instruction, which means you will skip it. Finally you will move whatever is located inside of rbp-0x4 into eax, which will be the value you got from the subtraction operation.

To break it down simply, your answer will be the result of 0x9fe1a - 0x65 in decimal notation which is 654773. You wrap that in academy to get your flag.

## Flag

```bash
academy{654773}
```

## Mitigation

Don't make the problem so easy, longer and harder problems make it harder for attacker to reverse