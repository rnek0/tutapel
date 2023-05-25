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

server="127.0.0.1"
port="0"

# Get name server
function serverName(){
    server=$1
    port=$2
    fd="/dev/tcp/${server}/${port}"
    status=0
    
    # Check if port is open.
        timeout 1 bash -c "(echo '' > $fd) 2>/dev/null" && echo -e " ${grayColour}[+] Port $port open" || status=$(( $status + 1 )) 
        if [ "$status" != "0" ]; then
            echo -e " ${redColour}[!]${endColour} Service unavailable.\n"
            exit 1
        fi
    # Server is available.
        if [ "$status" == "0" ] ; then
            server_name="$(exec 4<>"${fd}"; echo -e "GET / HTTP/1.1\r\nHost: ${server}/${port}/\r\nAccept: */*\r\nConnection: close\r\n\r\n" >&4 ; grep -E "^Server:." <&4;)"
            #exec 4<>${fd} && echo -e "GET / HTTP/1.1\r\nHost: ${server}/${port}/\r\nAccept: */*\r\nConnection: close\r\n\r\n" >&4 ; server_name=$(grep -E "^Server:." <&4)
            #server_name="$(exec 4<>"${fd}"; echo -e "GET / HTTP/1.1\r\nHost: ${server}/${port}/\r\nAccept: */*\r\nConnection: close\r\n\r\n" >&4 ; cat <&4;)"

            exec 4>&-
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

# Main
function main(){
    server=$1
    port=$2

    if [ $server ] && [ $port ]; then
        echo -e "\n${grayColour} Search ${purpleColour}${server}:${port}${endColour}"
        serverName $server $port
    else
        helpPanel
    fi;
}

# Menu
while getopts "s:p:,h" arg; do 
    case $arg in 
        s) server="$OPTARG";;
        p) port="$OPTARG"; if [[ $port -le 0 ]] || [[ $port -gt 65536 ]]; then helpPanel; fi; ;;
        h) helpPanel;;
    esac
done

# Start
if [ "$#" != "4" ]; then
    helpPanel
else
    main $server $port    
fi
