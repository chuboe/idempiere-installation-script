#!/usr/bin/expect -f
#this file will send the current inventory of plugins to console output.
#example usage: ./chuboe_osgi_ss.sh > somefile.txt
set plugin [lindex $argv 0]
puts $plugin
spawn telnet localhost 12612
send -- "install file:////$plugin\n"
send -- "disconnect\n\n"
expect "$ "