#!/usr/bin/bash

#set -euo pipefail

# Colors
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;90m\033[1m"
test_false="${redColour}FALSE${endColour}"
test_TRUE="${greenColour}TRUE${endColour}"

function ctrl_c(){
    echo -e "\n\n ${redColour}[!] Exit ...${endColour}\n"
    echo -e "\n ${grayColour}-------------------------------------------------------------${endColour}"
    tput cnorm
    exit 1
}

trap ctrl_c INT

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
    server_name=""
    server=$1
    port=$2
    fd="/dev/tcp/${server}/${port}"
    status=0
    tput civis
    # Check if port is open.
        timeout 1 bash -c "echo '' > /dev/tcp/${server}/${port}" 2>/dev/null && echo -e "\n ${grayColour}[+] Port $port open" || status=$(( $status + 1 )) 
        #wait
        sleep 1
        #kill %%
        if [ "$status" != "0" ]; then
            echo -e "\n ${redColour}[!]${endColour} Service unavailable.\n"
            echo -e " ${grayColour}-------------------------------------------------------------${endColour}"
            tput cnorm
            exit 1
        fi
    # Server is available.
        if [ "$status" == "0" ] ; then
            exec 4<>"${fd}"; echo -e "GET / HTTP/1.1\r\nHost: ${server}/${port}/\r\nAccept: */*\r\nConnection: close\r\n\r\n" >&4 ; server_name=$(grep -E "^Server:." <&4) 
            #server_name="$(exec 4<>"${fd}"; echo -e "GET / HTTP/1.1\r\nHost: ${server}/${port}/\r\nAccept: */*\r\nConnection: close\r\n\r\n" >&4 ; grep -E "^Server:." <&4;)"
            #server_name="$(exec 4<>"${fd}"; echo -e "GET / HTTP/1.1\r\nHost: ${server}/${port}/\r\nAccept: */*\r\nConnection: close\r\n\r\n" >&4 ; cat <&4)"
            #exec 4<>"${fd}"; echo -e "GET / HTTP/1.1\r\nHost: ${server}/${port}/\r\nAccept: */*\r\nConnection: close\r\n\r\n" >&4 ; cat <&4
            exec 4>&-
        else
            echo -e "${blueColour} [+]${yellowColour} Service unavailable.${endColour} \n"
            echo -e " ${grayColour}-------------------------------------------------------------${endColour}"
            tput cnorm
            exit 0
        fi
    # Display results.
        if [ "$server_name" != "" ]; then
            echo -e " ${blueColour}[+]${yellowColour} ${server_name}${endColour} \n"
            echo -e " ${grayColour}-------------------------------------------------------------${endColour}"
        else
            echo -e "\n ${blueColour}[+]${yellowColour} Could'n get server name.${endColour} \n"
            echo -e " ${grayColour}-------------------------------------------------------------${endColour}"
        fi;
    tput cnorm
}

# Main
function main(){
    server=$1
    port=$2
    iana_tlds="http://data.iana.org/TLD/tlds-alpha-by-domain.txt"

    # Ip or url ?
    valid_ip="$(echo ${server} | grep -E '^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$')"

    if [ "$valid_ip" == "" ] ; then
        # Remove protocol http(s):// if exists (simple regexp)
        remove_protocol="$(echo "$server" | grep -E '^(https?|ftp|file):/{2}(_|[a-zA-Z0-9])')"
        if [ $remove_protocol ]; then
            server="$(echo $server | sed 's|https\?://||g' )"
        fi
        
        # Get tld from server
        srv=$(echo "$server" | tr '[:lower:]' '[:upper:]')
        IFS='.'
        read -ra newarr <<< "$srv"
        tld="${newarr[-1]}"

        # Checking tld validity.
        reg="^${tld}$"
        isValidTld=0
        isValidTld="$(wget -qO- "${iana_tlds}" | grep -E "$reg" | wc -l 2>/dev/null)"

        if [ "$isValidTld" == "1" ] || [ "$server" == "localhost" ]; then
            echo -e "\n${grayColour} Search ${purpleColour}${server}:${port}${endColour}"
        else
            echo -e "\n ${redColour}[!] Needs a valid IP or URL.${endColour}"
            echo -e "\n ${grayColour}-------------------------------------------------------------${endColour}\n"
            tput cnorm
            exit 1
        fi

    else
        # C'est une IP !!!
        echo -e "\n${grayColour} Search ${purpleColour}${server}:${port}${endColour}"
    fi
    
    # Request server name
    if [ "${server}" != "" ] && [ "${port}" != "" ]; then
        echo -e " -------------------------------------------------------------"
        #echo -e "\n ${grayColour}${purpleColour}${server}:${port}${endColour}\n"
        serverName "${server}" "${port}"
        echo
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
