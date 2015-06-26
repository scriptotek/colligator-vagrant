#!/usr/bin/env tclsh

# * Gather data
set distro [exec -- lsb_release -s -d]
set memory  [exec -- free -m]
set mem(t)  [lindex $memory 7]
set mem(u)  [lindex $memory 8]
set mem(f)  [lindex $memory 9]
set mem(c)  [lindex $memory 16]
set mem(s)  [lindex $memory 19]

# * ASCII head
set head {
            _ _ _             _             
           | | (_)           | |            
   ___ ___ | | |_  __ _  __ _| |_ ___  _ __ 
  / __/ _ \| | | |/ _` |/ _` | __/ _ \| '__|
 | (_| (_) | | | | (_| | (_| | || (_) | |   
  \___\___/|_|_|_|\__, |\__,_|\__\___/|_|   
                   __/ |                    
                  |___/                     
}

# * Print Output
puts "  \033\[01;32m$head\033\[0m"
puts "  \033\[35mSystem........:\033\[0m \033\[36m$distro\033\[0m"
puts "  \033\[35mMemory MB.....:\033\[0m \033\[36m$mem(t)  Used: $mem(u)  Free: $mem(f)  Free Cached: $mem(c)  Swap In Use: $mem(s)\033\[0m"
puts "  \033\[35mBackend.......:\033\[0m \033\[36m/var/www/backend\033\[0m"
puts "  \033\[35mFrontend......:\033\[0m \033\[36m/var/www/frontend\033\[0m"
