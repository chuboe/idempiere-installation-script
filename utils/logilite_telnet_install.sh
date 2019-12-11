#!/usr/bin/expect -f
#

set plugin [lindex $argv 0]

spawn telnet localhost 12612
send -- "install file:///$plugin\n"
send -- "r\n"
send -- "disconnect\n\n"
expect "$ "