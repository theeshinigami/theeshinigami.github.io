## CTF: picoCTF 2024

Challenge: weirdSnake

Category: RE

Difficulty: Intermediate

## Instructions

I have a friend that enjoys coding and he hasn't stopped talking about a snake recently. He left this file on my computer and dares me to uncover a secret phrase from it.

Hints:
1. Download and try to reverse the python bytecode.
2. https://docs.python.org/3/library/dis.html

## Solution

This challenge requires learning Python bytecode to properly solve it.

### Python Bytecode

Python bytecode is the low-level instruction that CPython generates from your .py source code and executes via its virtual machine. The [docs](https://docs.python.org/3/library/dis.html) are useful.

Going step by step through the bytecode:

**Step 1 — Build input_list:**

```python
input_list = [21, 60, 43, 11, 86, 25, 38, 49, 33, 3, 0, 0, 57, 32, 108, 23, 48, 4, 9, 70, 7, 110, 36, 8, 108, 7, 49, 10, 4, 86, 43, 104, 126, 13, 87, 67, 60, 43, 12, 78]
```

**Step 2 — Build key_str (the tricky part):**

Watch carefully at the order of LOAD_CONST vs LOAD_NAME. It's easy to skim and think it's building "J_o3t" but you'd be wrong. You have to look at the position of when it loaded the const and the variable key_str:

```
J
_ + J = _J
_J + o = _Jo
_Jo + 3 = _Jo3
t + _Jo3 = t_Jo3
```

Key_str = `t_Jo3`

**Step 3 — Convert to key_list:**

```python
key_list = []
for char in key_str:
    key_list.append(ord(char))
```

**Step 4 — Extend key_list to match input_list length:**

```python
while(len(key_list) < len(input_list)):
    key_list.extend(key_list)
```

**Step 5 — XOR and join:**

```python
result = []
for i in range(len(key_list)):
    result.append(input_list[i] ^ key_list[i])
result_text = ''.join(map(chr, result))
print(result_text)
```

## Flag

```
academy{N0t_sO_coNfus1ng_sn@ke_74bd7cac}
```

## Mitigation

Add more obfuscation so it isn't as straightforward to reverse.
