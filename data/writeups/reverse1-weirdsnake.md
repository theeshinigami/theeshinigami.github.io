## CTF: picoCTF 2024

Challenge: weirdSnake

Category: RE

Difficulty: Intermediate

## Instructions

I have a friend that enjoys coding and he hasn't stopped talking about a snake recently.
He left this file on my computer and dares me to uncover a secret phrase from it. Can you assist?

Hints:

1. Download and try to reverse the python bytecode.
2. [https://docs.python.org/3/library/dis.html](https://docs.python.org/3/library/dis.html)

## Solution

So this challenge wasn't too bad, but had some tricks that obfuscated the secret text and required learning python bytecode to properly solve the challenge, so lets go over it.

### Python Bytecode

Python Bytecode is the low level instruction that CPython generates from your .py source code and executes via its virtual machine. In simple terms, Python bytecode is a set of basic instructions that Python creates so the computer knows how to run your code. There are certain important instructions that you will have to learn before properly completing this example. The docs for it are pretty useful, so I'll leave it down below.

[https://docs.python.org/3/library/dis.html](https://docs.python.org/3/library/dis.html)

This requires going step by step to build your own python script, so I will try to put the bytecode and my code side by side to show my thought process in solving this challenge. Lets start with the first few lines of the bytecode.

```bash
  0           0 RESUME                   0

  1           2 BUILD_LIST               0
              4 LOAD_CONST               0 ((21, 60, 43, 11, 86, 25, 38, 49, 33, 3, 0, 0, 57, 32, 108, 23, 48, 4, 9, 70, 7, 110, 36, 8, 108, 7, 49, 10, 4, 86, 43, 104, 126, 13, 87, 67, 60, 43, 12, 78))
              6 LIST_EXTEND              1
              8 STORE_NAME               0 (input_list)

```

This is calling build list, which literally builds a list. From what I have seen, python bytecode seems to do stuff backwards, as it calls BUILD_LIST, loads the contents, and then names the list which in this case is input_list. This is good to know though, we just need to make a list called input_list in python as such.

```bash
    input_list = [21, 60, 43, 11, 86, 25, 38, 49, 33, 3, 0, 0, 57, 32, 108, 23, 48, 4, 9, 70, 7, 110, 36, 8, 108, 7, 49, 10, 4, 86, 43, 104, 126, 13, 87, 67, 60, 43, 12, 78]

```

Lets look at the next part, which was arguably the hardest part for me.

```bash
2          10 LOAD_CONST               1 ('J')
             12 STORE_NAME               1 (key_str)

  3          14 LOAD_CONST               2 ('_')
             16 LOAD_NAME                1 (key_str)
             18 BINARY_OP                0 (+)
             22 STORE_NAME               1 (key_str)

  4          24 LOAD_NAME                1 (key_str)
             26 LOAD_CONST               3 ('o')
             28 BINARY_OP                0 (+)
             32 STORE_NAME               1 (key_str)

  5          34 LOAD_NAME                1 (key_str)
             36 LOAD_CONST               4 ('3')
             38 BINARY_OP                0 (+)
             42 STORE_NAME               1 (key_str)

  6          44 LOAD_CONST               5 ('t')
             46 LOAD_NAME                1 (key_str)
             48 BINARY_OP                0 (+)
             52 STORE_NAME               1 (key_str)

```

This builds something called "key_str" with some values getting added to it with the "BINARY_OP" instruction. It's also loading constants into the key_str and adding other constants to it. The reason I say this is the hardest part is because it's so easy to skim over without looking at it closely. It would be easy to say it's just building the string "J_o3t" and move on, but you would be mistaken. You have to look at the position of when it loaded the const and the variable "key_str". This will give you an entirely new key_str which will set you up for success. Below is how it actually builds the string

```bash
J
_+J = _J
_J+o=_Jo
_Jo+3=_Jo3
t+_Jo3 = t_Jo3

```

This will give you the correct key_str and correct flag in the end.

Lets look at the next parts of the code.

```bash

  9          54 LOAD_NAME                1 (key_str)
             56 GET_ITER
             58 LOAD_FAST_AND_CLEAR      0 (char)
             60 SWAP                     2
             62 BUILD_LIST               0
             64 SWAP                     2
        >>   66 FOR_ITER                10 (to 90)
             70 STORE_FAST               0 (char)
             72 PUSH_NULL
             74 LOAD_NAME                2 (ord)
             76 LOAD_FAST                0 (char)
             78 CALL                     1
             86 LIST_APPEND              2
             88 JUMP_BACKWARD           12 (to 66)
        >>   90 END_FOR
             92 SWAP                     2
             94 STORE_FAST               0 (char)
             96 STORE_NAME               3 (key_list)

```

It's loading the variable "key_str" and GET_ITER is getting ready to loop over the key_str. We make and NULL out a new variable "char" and then initialize a new list "key_list". We then loop over the key_str and we store that value into "char". We then ord that value in "char" and add it to the "key_list".

```bash
    key_list = []
    for char in key_str:
        key_list.append(ord(char))
```

Next part just extends the key_list so that it matches the length of the input_list

```bash
11          98 PUSH_NULL
            100 LOAD_NAME                4 (len)
            102 LOAD_NAME                3 (key_list)
            104 CALL                     1
            112 PUSH_NULL
            114 LOAD_NAME                4 (len)
            116 LOAD_NAME                0 (input_list)
            118 CALL                     1
            126 COMPARE_OP               2 (<)
            130 POP_JUMP_IF_FALSE       35 (to 202)

 12     >>  132 LOAD_NAME                3 (key_list)
            134 LOAD_ATTR               11 (NULL|self + extend)
            154 LOAD_NAME                3 (key_list)
            156 CALL                     1
            164 POP_TOP

 11         166 PUSH_NULL
            168 LOAD_NAME                4 (len)
            170 LOAD_NAME                3 (key_list)
            172 CALL                     1
            180 PUSH_NULL
            182 LOAD_NAME                4 (len)
            184 LOAD_NAME                0 (input_list)
            186 CALL                     1
            194 COMPARE_OP               2 (<)
            198 POP_JUMP_IF_FALSE        1 (to 202)
            200 JUMP_BACKWARD           35 (to 132)
```

You can tell that it's a while loop because it keeps jumping backwards until the key_list is not less then the input_list. At line 132, you can also tell that it's extending the key_list by itself until it reaches the length or greater than the input_list. You can signify that with the code below.

```bash
    while(len(key_list) < len(input_list)):
        key_list.extend(key_list)
```

Now for the finale, we simply have to xor everything in the input_list with everything from the key_list to get our result, and then join everything to get out final string.

```bash
 15     >>  202 PUSH_NULL
            204 LOAD_NAME                6 (zip)
            206 LOAD_NAME                0 (input_list)
            208 LOAD_NAME                3 (key_list)
            210 CALL                     2
            218 GET_ITER
            220 LOAD_FAST_AND_CLEAR      1 (a)
            222 LOAD_FAST_AND_CLEAR      2 (b)
            224 SWAP                     3
            226 BUILD_LIST               0
            228 SWAP                     2
        >>  230 FOR_ITER                10 (to 254)
            234 UNPACK_SEQUENCE          2
            238 STORE_FAST               1 (a)
            240 STORE_FAST               2 (b)
            242 LOAD_FAST                1 (a)
            244 LOAD_FAST                2 (b)
            246 BINARY_OP               12 (^)
            250 LIST_APPEND              2
            252 JUMP_BACKWARD           12 (to 230)
        >>  254 END_FOR
            256 SWAP                     3
            258 STORE_FAST               2 (b)
            260 STORE_FAST               1 (a)
            262 STORE_NAME               7 (result)

 18         264 LOAD_CONST               6 ('')
            266 LOAD_ATTR               17 (NULL|self + join)
            286 PUSH_NULL
            288 LOAD_NAME                9 (map)
            290 LOAD_NAME               10 (chr)
            292 LOAD_NAME                7 (result)
            294 CALL                     2
            302 CALL                     1
            310 STORE_NAME              11 (result_text)
            312 RETURN_CONST             7 (None)
        >>  314 SWAP                     2
            316 POP_TOP

```

It calls zip, which just makes sure that everything from input_list has a match with something from the key_list. Since they are both the same length, you don't necessarily have to zip them together. After it does all the xoring, you have to join everything together and also map everything to a chr before you join them, to get the final string. The final code is shown below.

```bash
    result = []
    for i in range(len(key_list)):
        result.append(input_list[i]^key_list[i])
    result_text = ''.join(map(chr, result))
    print(result_text)
```

After all this, you'll finally have a full script to get the flag.

## Flag

```bash
academy{N0t_sO_coNfus1ng_sn@ke_74bd7cac}
```

## Mitigation

Honestly really well made challenge, but would recommend adding more obfuscation so it isn't as straightforward to reverse.