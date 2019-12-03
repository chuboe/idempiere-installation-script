#!/usr/bin/expect -f
#

set plugin [lindex $argv 0]

set id [lindex $argv 1]

set start [lindex $argv 2]

if { $start eq ""} {
    set start "5"
}

spawn telnet localhost 12612
send -- "update $id file:///$plugin\n"
send -- "bundlelevel -s $start $id\n"
send -- "r\n"
send -- "disconnect\n\n"
expect "$ "