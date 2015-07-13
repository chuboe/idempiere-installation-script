#!/usr/bin/expect -f
log_user 0
spawn telnet localhost 12612
send -- "exit\n\n"
expect "$ "
