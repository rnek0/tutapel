#!/usr/bin/bash

set -euo pipefail

# Colors
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;90m\033[1m"

# Help
function helpPanel(){
    echo -e "\n${redColour} [!]${grayColour} Use:${purpleColour} $0${endColour}"
    echo -e "\t${blueColour}-s)${grayColour} Server name or ip${endColour}"
    echo -e "\t${blueColour}-p)${grayColour} Server port${endColour}"
    echo -e "\n${redColour} Exemples:\n\t${purpleColour} $0 -s 127.0.0.1 -p 80${endColour}"
    echo -e "${redColour} \t${purpleColour} $0 -s localhost -p 80${endColour}\n"
    exit 0
}

# Get name server
function serverName(){
    server=$1
    port=$2
    fd="/dev/tcp/${server}/${port}"
    status="ok"
    
    # Ping.
        (ping -c 1 "$server") &>/dev/null && echo -e " [+] ping $server up" || echo -e "${redColour} [!]${yellowColour} Server $server down" && status="exit" &  
    # Check if port is open.
        (echo '' > $fd) 2>/dev/null && echo -e " [+] ping $port open" || echo -e "${redColour} [!]${yellowColour} Port $port closed" && status="exit" &
    # Server is available.
        if [ "$status" == "ok" ] ; then
            #server_name="$(exec 4<>"${fd}"; echo -e "GET / HTTP/1.1\r\nHost: ${server}/${port}/\r\nAccept: */*\r\nConnection: close\r\n\r\n" >&4 ; grep -E "^Server:." <&4;)"
            exec 4<>${fd} && echo -e "GET / HTTP/1.1\r\nHost: ${server}/${port}/\r\nAccept: */*\r\nConnection: close\r\n\r\n" >&4 ; server_name=$(grep -E "^Server:." <&4)
            #server_name="$(exec 4<>"${fd}"; echo -e "GET / HTTP/1.1\r\nHost: ${server}/${port}/\r\nAccept: */*\r\nConnection: close\r\n\r\n" >&4 ; cat <&4;)"
        else
            echo -e " ... Service unavailable :(\n"
            exit 0
        fi
    # Display results.
        if [ "$server_name" != "" ]; then
            echo -e "${blueColour} [+]${yellowColour} ${server_name}${endColour} \n"
        else
            echo -e "${blueColour} [+]${yellowColour} Could'n get server name.${endColour} \n"
        fi;
}

# Menu
noargs="true"
while getopts "s:p:,h" arg; do 
    case $arg in 
        s) server="$OPTARG";;
        p) port="$OPTARG"; if [[ $port -lt 0 ]] || [[ $port -gt 65536 ]]; then helpPanel; fi; ;;
        h) helpPanel;;
    esac
    noargs="false"
done

if [ "$noargs" == "false" ] && [ -z "$server" ] || [ -z "$port" ]; then
    helpPanel
else
    echo -e "\n${grayColour} ... server search :${purpleColour} ${server}:${port}${endColour}\n"
    serverName $server $port
fi;
