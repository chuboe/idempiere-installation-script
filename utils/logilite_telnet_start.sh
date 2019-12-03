#!/usr/bin/expect -f
#

set id [lindex $argv 0]

spawn telnet localhost 12612
send -- "start $id\n"
send -- "disconnect\n\n"
expect "$ "