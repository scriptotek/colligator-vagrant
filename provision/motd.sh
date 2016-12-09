#!/usr/bin/env tclsh

# * Gather data
distro=$(cat /etc/redhat-release)
memory=($(exec -- free -m))

# * ASCII head
head=$(cat <<'EOF'
             _ _ _             _             
            | | (_)           | |            
    ___ ___ | | |_  __ _  __ _| |_ ___  _ __ 
   / __/ _ \| | | |/ _` |/ _` | __/ _ \| '__|
  | (_| (_) | | | | (_| | (_| | || (_) | |   
   \___\___/|_|_|_|\__, |\__,_|\__\___/|_|   
                    __/ |                    
                   |___/                     
EOF
)

# * Print Output
printf "\e[01;32m$head\e[0m\n\n"
printf "  \e[35mSystem........:\e[0m \e[36m$distro\e[0m\n"
printf "  \e[35mMemory MB.....:\e[0m \e[36m${memory[7]}  Used: ${memory[8]}  Free: ${memory[9]}  Free Cached: ${memory[16]}  Swap In Use: ${memory[19]}\e[0m\n"
printf "  \e[35mBackend.......:\e[0m \e[36m/var/www/backend\e[0m\n"
printf "  \e[35mFrontend......:\e[0m \e[36m/var/www/frontend\e[0m\n"
printf "  \e[35mEditor........:\e[0m \e[36m/var/www/editor\e[0m\n"
