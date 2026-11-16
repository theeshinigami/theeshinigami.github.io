> Short field notes — to be expanded into a full walkthrough.

First we have to get to the box with a reverse callback on port 80.

Then we get the SSH keys to get the SSH public key (or generate it).

Then we can see the router's SSH key and its config file, which has the IP.

We can get on the router and start listening on `tcpdump`, which gives us our pcap.

Then analyze the pcap with our profiler and Wireshark.
