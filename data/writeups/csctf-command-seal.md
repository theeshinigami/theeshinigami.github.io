So I didn't get this one myself (AI did), but a writeup done by myself will still be very useful. Essentially, you started with a page that gave you all the information you needed.

You have `/report`, `/order`, and a file that is given to you. This is screaming XML entity stuff. The basis for XML entity file leaks is shown below.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE foo [ <!ENTITY xxe SYSTEM "file:///opt/relay/outbox/last-order.txt"> ]>
<report><summary>&xxe;</summary></report>
```

We can create an entity pointing to the file path, and as long as it's reflected to us, we should be able to see the file. This is great for us as we can now read the contents of the file.

We read the content of the file and see it lines up exactly with our `/order` format, so we now know we can fill out all the correct options in the order and the auth check. How do we get our flag? Well the auth only checks to see if the correct order is in place, not if the first one is valid. So we can make an order for the standing and eventually it'll find the correct order and pass the check. So we can put some false input and then the real input to receive our flag. Just make sure there are no newline characters.
