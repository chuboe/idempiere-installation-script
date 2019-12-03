#!/usr/bin/expect -f
#

set id [lindex $argv 0]

set start [lindex $argv 1]

if { $start eq ""} {
    set start "5"
}

spawn telnet localhost 12612
send -- "bundlelevel -s $start $id\n"
send -- "r\n"
send -- "disconnect\n\n"
expect "$ "