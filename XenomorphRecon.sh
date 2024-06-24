#!/bin/bash
# XenomorphRecon - Advanced Reconnaissance Script
# Author: Rogue Payload
# Purpose: Comprehensive reconnaissance tool with a sci-fi twist

# Color Definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if a command is available
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}$1 is not installed. Please install $1 to proceed.${NC}"
        exit 1
    else
        echo -e "${GREEN}$1 is already installed.${NC}"
    fi
}

# Required tools
tools=("nslookup" "dig" "curl" "nikto" "nmap" "whatweb" "gobuster" "sslscan")

# Check and notify if required tools are installed
for tool in "${tools[@]}"; do
    check_command $tool
done

# Function to validate and parse the input
parse_input() {
    local input=$1

    # Check if input is an IP address block (CIDR notation)
    if [[ $input =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        echo -e "${GREEN} IP Address Block: $input${NC}"
        return 0
    fi

    # Check if input is a valid IP address
    if [[ $input =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo -e "${GREEN} IP Address: $input${NC}"
        return 0
    fi

    # Check if input is a valid domain or subdomain
    if [[ $input =~ ^[a-zA-Z0-9.-]+$ ]]; then
        # Attach https:// if not present
        if [[ $input != http* ]]; then
            input="https://$input"
        fi
        echo -e "${BLUE} Domain or Subdomain: $input${NC}"
        return 0
    fi

    echo -e "${RED} Invalid input. Please enter a valid IP address, domain, or IP address block.${NC}"
    return 1
}

# Gather User Input
while true; do
    read -p "Enter the target URL, IP Address, or IP Address Block: " target
    if parse_input "$target"; then
        break
    fi
done

# Use the parsed target
echo -e "${RED} Locking On Target: $target${NC}"

# Progress Bar Function
progress_bar() {
    local duration=$1
    already_done() { for ((done=0; done<$elapsed; done++)); do printf "${YELLOW}▇"; done }
    remaining() { for ((remain=$elapsed; remain<$duration; remain++)); do printf " "; done }
    percentage() { printf "${GREEN}| %s%%" $(( (elapsed*100)/duration )); }

    for ((elapsed=1; elapsed<=duration; elapsed++))
    do
        printf "\r%s%s%s" "$(already_done)" "$(remaining)" "$(percentage)"
        sleep 0.1
    done
    printf "\n"
}

# Run Tools and Collect Data
run_tool() {
    local tool=$1
    local cmd=$2
    local file=$3

    echo -e "${BLUE}Now Running: $tool on $target${NC}"
    progress_bar 50
    echo -e "${YELLOW}Output:${NC}" >> $file
    eval $cmd >> $file
    echo -e "${GREEN}$tool finished.${NC}\n"
}

output_file="${target}_recon.txt"
echo -e "${GREEN}Starting reconnaissance on $target${NC}" > $output_file

# nslookup
run_tool "nslookup" "nslookup $target" $output_file

# dig
run_tool "dig" "dig $target" $output_file

# curl
run_tool "curl" "curl -I $target" $output_file

# nikto
run_tool "nikto" "nikto -h $target" $output_file

# nmap
run_tool "nmap" "nmap -A $target" $output_file

# whatweb
run_tool "whatweb" "whatweb $target" $output_file

# gobuster
run_tool "gobuster" "gobuster dir -u http://$target -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt" $output_file

# sslscan
run_tool "sslscan" "sslscan $target" $output_file

# Display Final Results
echo -e "${GREEN}Reconnaissance completed on $target. Results:${NC}"
cat $output_file

# Ask to Save Results
read -p "Do you want to save the results to a file? (y/n): " save_results
if [[ $save_results == "y" || $save_results == "Y" ]]; then
    echo -e "${GREEN}Results saved to ${output_file}${NC}"
else
    rm $output_file
    echo -e "${RED}Results discarded.${NC}"
fi
