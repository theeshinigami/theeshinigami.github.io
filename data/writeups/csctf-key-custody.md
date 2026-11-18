## JWT and KID

A JSON Web Token (JWT) is just used to securely pass information between parties. It consists of a header, payload, and signature. A Key Identidier (KID) is an optional field that hints to what is actually signing the token. If the server does not treat the KID as just a label, but actually uses it to look up stuff in a database, this means it is vulnerable to a lot of different attacks, most commonly directory traversal with a known file on the webserver.

## Solution

You are brought to a page that has a few endpoints for you to look at. It tells you to go to three endpoints

```bash
/admin/recovery-key
/public
/schema
/token
```

Going to schema, you get told how the backend works and it gives you a hint about how kid works. The hint of the challenge also hints to the kid vector being the vulnerable part. The token endpoint gives you a static token that you need to somehow manipulate to hit the /admin/recovery-key to get the flag. You can pull it and you'll see how the token is broken down. Here are the header and payload fields

```bash
{
  "alg": "HS256",
  "typ": "JWT",
  "kid": "session"
}
{
  "sub": "analyst-recon-17",
  "role": "analyst"
}
```

When you try to access the recovery-key endpoint with the issued token, it says that only the issued analyst with the token role=admin can view it. You can try changing the role directly, but all you will get is "invalid token". So what to do then? Well you can try to do some directory traversal on the kid value to get a known file on the website and sign that key with the bytes of the file. This allows you to get a valid key that's signed properly and a role of admin, giving you access to the recovery-key. We need to find a valid file though. This is where the public directory comes into, which I will say took a long time to find. Lesson learned, if traditional wordlists don't work, using cewl and some file extensions never hurt. Point is, after a lot of fuzzing, the file in public.txt is **brand.txt.** The contents of the file are left below.

```bash
Vardanne Command — Vardanne Joint Operations Directorate
Console asset: brand banner v3. Property of the Directorate.
Unauthorized access to this system is an offence under the Emergency Powers Act.
```

Using the contents of this file, we are now able to sign a proper JWT token and successfully retrieve the flag.