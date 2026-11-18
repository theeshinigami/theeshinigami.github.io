So this challenge involved looking at an access log and regainging the secrets from it. It's a huge file, but when you start scrolling down, you see some suspicious inputs.

```bash
GET /api/status?unit=43'+AND+IF(SUBSTR(token,4,1)='T',SLEEP(2),0)-
```

You see so many of these, I guessed it could only be someone bruteforcing the password. That means all we need to do is find the success condition, and then the letters associated with those successes condtions. Looking closer at the data, the only success condition would be the **rt=NUM** section. If it is abnormally high, then it most have succeeded, classic server side channel attack. Sorting by the rt field, you see that some of the requests get up to two seconds, much longer then the 0.01 milliseconds. Here's the command I did to run this.

```bash
grep AND+IF access.log | cut -d "=" -f4 | sort -n
```

With this, we should try to find all those  requests whose rt is greater than 2 seconds, and than parse them for the flag. Here are the final commands I did to find this.

```bash
grep rt=2.* onlybrute | sort -n -t, -k2 | cut -d "=" -f3 | cut -d "," -f1 > final
```

```bash
>>> with open("final","r") as f:
...     data = f.readlines()
...     string = ""
...     for i in data:
...         string += i[1].strip()
...
>>> print(string)
CSCTF%07_beacon_tow_vigil_bollard_8c0371%

```