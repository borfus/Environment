############################## PATH ##############################

# Java Paths
PATH=$PATH:/usr/lib/jvm/java-11-openjdk-amd64/bin
PATH=$PATH:/usr/lib/jvm/java-8-openjdk-amd64/bin

# Script path
PATH=$PATH:~/scripts
PATH=$PATH:/home/borfus/.local/bin

# 010 Editor 
PATH=$PATH:/home/borfus/010editor;export PATH; # ADDED BY INSTALLER - DO NOT EDIT OR DELETE THIS COMMENT - 87FF8EFC-483D-BCAA-D67D-735CF60410D1 DEB385BD-25BD-6270-356F-72EFDB692649

# Remove duplicate paths from $PATH
typeset -U path PATH

############################# ENV VARS ############################

# fzf setup
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Cargo setup
. "$HOME/.cargo/env"

# find first part with 'echo $(rustc --print sysroot)'
export RUST_SRC_PATH=/home/borfus/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/library/

############################## SHELL ##############################

# History timestamp
export HISTTIMEFORMAT="%d/%m/%y %T "

# Add color to ls command
export CLICOLOR=1

# Enable console coloring
force_color_prompt=yes

# Total history line storage - default 2000
HISTFILESIZE=50000

# Hide User/Group in shell
PS1='%F{green}[%~] $%f '

# Case-insensitive tab completion
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Git branch tab-completion
autoload -Uz compinit && compinit

# Nvidia Shader Cache
export __GL_SHADER_DISK_CACHE_PATH='/home/borfus/shader-cache'
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1

############################## ALIAS ##############################

# Quickly access .zshrc
alias vibash='nvm && nvim ~/.zshrc && source ~/.zshrc'

# Open i3 config
alias i3conf='nvm && nvim ~/.config/i3/config'

# Open notes.txt file quickly
alias vinotes='nvm && nvim ~/notes.txt'

# Quickly access .vimrc
alias vimrc='nvm && nvim ~/.vimrc'

# Load vim without plugins
alias vimnone='nvm && nvim -u NONE'

# Quickly access .inputrc
alias vimput='nvm && nvim ~/.inputrc'

# Alias to change vim to run nvim since I'm too used to typing vim
alias vim='nvm && nvim'
alias ovim='nvm && /usr/bin/vim'

# Color search with grep
alias grip='grep -rn --color=always --ignore-case'

# Color search java files with grep
alias javagrip='grep -rn --color=always --ignore-case --include=\*.java'

# Color search c files with grep
alias cgrip='grep -rn --color=always --ignore-case --include=\*.c'

# Color search h files with grep
alias hgrip='grep -rn --color=always --ignore-case --include=\*.h'

# Easy file finding
alias qfind='sudo find . -iname'
alias afind='sudo find / -iname'

# Quick list
alias ls='ls --color=auto'
alias la='ls --color=auto -a'
alias ll='ls --color=auto -lathr'

# Quick find process
alias psa='ps -a | grep'

# Easy Navigation for zsh 
alias ..='cd ../'                   # Go back 1 directory level
alias .2='cd ../../'                # Go back 2 directory levels
alias .3='cd ../../../'             # Go back 3 directory levels
alias .4='cd ../../../../'          # Go back 4 directory levels
alias .5='cd ../../../../../'       # Go back 5 directory levels
alias .6='cd ../../../../../../'    # Go back 6 directory levels
alias c='clear'                     # c: Clear terminal display

# Quick dir navigate
alias f='xdg-open .'                # f: Opens current directory in finder
#alias f='ranger'                    # f: Opens current directory in finder
alias ~="cd ~"                      # ~: Go Home
alias desk='cd ~/Desktop/'
alias down='cd ~/Downloads/'
alias dp="cd /DevProjects/"

# Quickly extract tar.gz file
alias untar='tar xvf'

# Alias because I'll eventually forget the name of this program
alias img='geeqie'

alias ports='sudo lsof -i -P -n | grep LISTEN'

# Change diff to icdiff
alias diff='icdiff -N'

# Copy input to clipboard
alias pbcopy="xclip -sel clip"

# Quickly clear trash bin
alias rmtrash='rm -rf ~/.local/share/Trash/*'

# Quickly install .deb file
alias deb='sudo dpkg -i'

# Quickly update/upgrade
alias in='sudo apt-get install'
alias up='sudo apt-get update'
alias ug='sudo apt-get upgrade'
alias dup='sudo apt-get dist-upgrade'
alias ar='sudo apt-get autoremove'
alias search='apt-cache search'
alias flatup='flatpak update'

# Pass in OP token after sign-in
alias qop='eval $(op signin my) --output=raw'

# Fix lineendings
alias linefix='sed -i -e "s/\r$//"'

# Quick CPU temp
alias temp='acpi -t'

# Quick Wi-Fi
alias wifi='nmtui'
alias wificli='nmcli device wifi' #use connect 'ssid' password 'password'

# Quick clear history
alias rmhistory='cat /dev/null > ~/.zsh_history && history -c'

# Update and sync local time
alias timefix='sudo ntpd -qg'

# Gitk & but quicker
alias gitdiff='gitk &'

# Enable wifi (useful for recovery mode)
alias enablewifi='sudo service network-manager start'

## Python ##

# Shorthand for Python 3 and 2
alias py='/usr/bin/python3'
alias py2='/usr/bin/python'

alias uuidgenlower='uuidgen | tr "[:upper:]" "[:lower:]"'

# Protontricks alias for Steam
alias protontricks-flat='flatpak run --command=protontricks com.valvesoftware.Steam --no-runtime'

# System76 Power Profiles
alias powerh='system76-power profile performance'
alias powerm='system76-power profile balanced'
alias powerl='system76-power profile battery'
alias graphn='system76-power graphics nvidia'
alias graphh='system76-power graphics hybrid'
alias graphi='system76-power graphics integrated'
alias power='system76-power profile'
alias cputemp='watch -n 2 sensors'
alias gputemp='watch -n 2 nvidia-smi'

# System76 BIOS Update
alias biosupdate='system76-firmware-cli schedule'

############################## SCRIPTS ##############################

# Use fzf to open files
ff() { du -a ~ /DevProjects | awk '{print $2}' | fzf | xargs -r nvim; }

# mcd: Makes new Dir and jumps inside
mcd() { mkdir -p "$1" && cd "$1"; }

# mvnotes: Move the notes.txt file to the notes folder with a new name
mvnotes() { mv ~/notes.txt ~/notes/$1; }

# Call `fzip foldername` to zip a folder
fzip() { zip -r $1{.zip,}; }

# Search and replace strings in files recursively
sr() { find . -type f -exec sed -i -e 's#'"$1"\#"$2"'#g' {} \;; }

# Search and replace filenames recursively
srf() { find . -depth -name \*"$1"\* -execdir zsh -c 'mv -i "$1" "${1//'"$1"/"$2"'}"' zsh {} \;; }

# Convert a hex file to base64 then back to the original file
hex2file() { cat "$1" | xxd -r -p | base64 | base64 --decode > "$2"; }

# Prepend text to file
prep() { echo "$2" | cat - $1 > temp && mv temp $1; }

# Search git diffs and grep text
gitgrep() { git log -S"$1" -p --all; }

# Quickly open pdf with Zathura
pdf() { zathura "$1" & }

# Remove all files (recursively) with a specific pattern
rmpat() { find . -name "$1" -delete; }

# Allow a port through firewall
addport() { sudo ufw allow "$1"; }

# Kill all processes using a specific port
killport() { kill $(lsof -t -i :"$1"); }

# Find a file by name
findq() { sudo find . -name "$1" 2>/dev/null; }
finda() { sudo find / -name "$1" 2>/dev/null; }

# Download video from network request link m3u8
downvid() { ffmpeg -i "$1" -c copy -bsf:a aac_adtstoasc "output.mp4"; }

# Load nvm on command to prevent it from loading on startup
loadnvm() {
    NVM_DIR="$HOME/.nvm";
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh";  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion";  # This loads nvm bash_completion
}

nvm() {
    unfunction nvm
    loadnvm
    nvm "$@"
}

