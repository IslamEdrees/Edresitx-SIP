#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No color

# Declare trunks and their IP addresses
declare -A trunks=(
    ["NAMEXXXX"]="TrunkIDxx.xx.xx.xx"
    ["NAMEXXXX"]="TrunkIDxx.xx.xx.xx"
    ["NAMEXXXX"]="TrunkIDxx.xx.xx.xx"
    ["NAMEXXXX"]="1TrunkIDxx.xx.xx.xx"
    ["NAMEXXXX"]="TrunkIDxx.xx.xx.xx"
)

port=5060

# Function to print logo
print_logo() {
    echo -e "                                  ___....."
    echo -e "                              (:            \`."
    echo -e "                            '  (     EDRESTIX  ."
    echo -e "                            (' \`.           ':  :"
    echo -e "                           ( (.'- .==._   _= :  \`."
    echo -e "                           \`_(   ' @@' \`.'@@\`-\\_:'"
    echo -e "                             :\`         .     ::"  
    echo -e "                             :: \\   .'_JJ \\  ':."
    echo -e "                             =-\`._.'_.::::.\`_:'=."
    echo -e "                            .-:-.=:-::.____=:-:=-"
    echo -e "                             -:/-:.'=:/::.\\.-=:= "
    echo -e "                              '././:/.::|,\\\`:\\=.a._"
    echo -e "                              ba''/:|:|::|:\\\\\`888888."
    echo -e "                          _.a(88/  _.='\\\.   .a388888888a."
    echo -e "                      _.a8883a8/.:\"'    \`:.a838888888888aa."
    echo -e "                  _.a888888388/''        ')'83888888888888888)"
    echo -e "                .888888888388/           (:838888888888888888)"
    echo -e "               .888888888388P EDRESTIX /8\"8888888888888888a88)"
    echo -e "               888888888838P           /8888888888P8888888P88'"
    echo -e "               888888888838           /88388888888a88888888P'"
    echo -e "               888888888838:         /88388888888P888888P\""
    echo -e "                88a88888838a        /88388888888a8888P\""
    echo -e "                 \"P888888388a      /88388888888a888P'"
    echo -e "                     Edrestix"
}

# Function for SIP status
check_sip_status() {
    echo -e "${YELLOW}Checking SIP Status...${NC}"
    sudo asterisk -rx "sip show peers" | grep "Name" -A 10
    read -p "Press Enter to continue..."
}

# Function to check trunk status (reachable or unreachable)
check_trunk_status() {
    local trunk=$1
    local ip=$2
    ping -c 1 -W 1 $ip &> /dev/null
    if [[ $? -eq 0 ]]; then
        echo "$trunk at $ip on port $port is OK"
        status="OK"
    else
        echo "$trunk at $ip on port $port is UNREACHABLE"
        status="UNREACHABLE"
    fi
}

# Function to count calls for each trunk
count_calls() {
    local trunk=$1
    if [[ "$trunk" == "NAMEXXXXhere" ]]; then
        sent_count=$(sudo asterisk -rx "core show channels" | grep -c "SIP/NAMEXXXX spesific")
        received_count=$(sudo asterisk -rx "core show channels" | grep -c "SIP/NAMEXXXX spesific.*Dial")
        echo "$trunk | Sent: $sent_count | Received: $received_count"
    else
        received_count=$(sudo asterisk -rx "core show channels" | grep -c "SIP/$trunk")
        forwarded_to_=$(sudo asterisk -rx "core show channels" | grep -c "SIP/NAMEXXXX spesific.*SIP/$trunk")
        echo "$trunk | Received: $received_count | Forwarded to NAMEXXXX spesific: $forwarded_to_btech"
    fi
}

# Function for trunk status and call counts
monitor_trunk_status() {
    echo -e "${YELLOW}Monitoring Trunk Status and Call Counts...${NC}"
    # Print headers
    echo "---------------------------------------------"
    printf "%-15s %-20s %-15s %-15s\n" "Trunk" "IP Address" "Status" "Call Counts"
    echo "---------------------------------------------"

    # Loop through trunks and display their status and call counts
    for trunk in "${!trunks[@]}"; do
        ip=${trunks[$trunk]}
        check_trunk_status $trunk $ip
        count_calls $trunk
        echo "---------------------------------------------"
    done

    # Display detailed Asterisk channel information
    core_show_channels=$(sudo asterisk -rx "core show channels verbose")
    echo "$core_show_channels"

    # Pause for 5 seconds before the next update
    sleep 20
}

# Function to check codecs
check_codecs() {
    echo -e "${YELLOW}Checking Available Codecs...${NC}"
    sudo asterisk -rx "core show codecs"
    read -p "Press Enter to continue..."
}

# Function for audio diagnostics
audio_diagnostics() {
    echo -e "${YELLOW}Running Audio Diagnostics...${NC}"
    echo "1. Checking active audio channels..."
    sudo asterisk -rx "core show channels" | grep -i 'audio'
    
    echo -e "\n2. Checking audio settings..."
    sudo asterisk -rx "core show settings" | grep -i 'audio'
    
    echo -e "\n3. Checking audio statistics..."
    sudo asterisk -rx "core show translation"
    read -p "Press Enter to continue..."
}

# Function to enable SIP debug
enable_sip_debug() {
    echo -e "${YELLOW}Enabling SIP Debug Mode...${NC}"
    sudo asterisk -rx "sip set debug on"
    echo -e "${GREEN}SIP Debug enabled. Check /var/log/asterisk/messages for debug output${NC}"
    read -p "Press Enter to continue..."
}

# Function to force re-registration
force_reregistration() {
    echo -e "${YELLOW}Forcing SIP Re-registration...${NC}"
    for trunk in "${!trunks[@]}"; do
        echo -e "Re-registering $trunk..."
        sudo asterisk -rx "sip reload"
        sudo asterisk -rx "sip qualify $trunk"
    done
    echo -e "${GREEN}Re-registration complete${NC}"
    read -p "Press Enter to continue..."
}

# Function to test firewall ports
test_firewall_ports() {
    echo -e "${YELLOW}Testing Firewall Ports...${NC}"
    local ports=(5060 10000 20000)  # Common SIP and RTP ports
    
    for trunk in "${!trunks[@]}"; do
        ip=${trunks[$trunk]}
        echo -e "\nTesting ports for $trunk ($ip):"
        for port in "${ports[@]}"; do
            nc -zv -w2 $ip $port 2>&1
        done
    done
    read -p "Press Enter to continue..."
}

# Function to test latency (ping)
test_latency() {
    # Print explanations in English before executing the function
    echo -e "${GREEN}Latency test will check the response time (latency) for each trunk in the array.${NC}"
    echo -e "${GREEN}The latency values will be classified as follows:${NC}"
    echo -e "${YELLOW} - Latency lower than 1 ms: WARNING!${NC}"
    echo -e "${GREEN} - Latency between 1 ms and 10 ms: Normal range.${NC}"
    echo -e "${YELLOW} - Latency between 10 ms and 50 ms: Acceptable but may be noticeable in some applications.${NC}"
    echo -e "${RED} - Latency higher than 50 ms: High latency, potential issue!${NC}"

    echo -e "${GREEN}Starting latency test now...${NC}"

    if [ ${#trunks[@]} -eq 0 ]; then
        echo -e "${RED}Error: No trunks found in the array!${NC}"
        return
    fi

    echo -e "${YELLOW}Trunks found: ${#trunks[@]}${NC}"  
    echo -e "${GREEN}Array has ${#trunks[@]} trunks.${NC}"

    for trunk in "${!trunks[@]}"; do
        ip=${trunks[$trunk]}
        
        echo -e "Testing latency for $trunk at $ip..."

        ping_output=$(ping -c 4 $ip)

        if echo "$ping_output" | grep -q 'avg'; then
            latency=$(echo "$ping_output" | grep 'avg' | awk -F'/' '{print $5}')
            echo -e "$trunk at $ip has an average latency of ${GREEN}$latency ms${NC}"
            
            if (( $(echo "$latency < 1" | bc -l) )); then
                echo -e "${YELLOW}WARNING: $trunk latency is lower than 1 ms! ($latency ms)${NC}"
            elif (( $(echo "$latency >= 1" | bc -l) && $(echo "$latency < 10" | bc -l) )); then
                echo -e "${GREEN}$trunk latency is within normal range ($latency ms).${NC}"
            elif (( $(echo "$latency >= 10" | bc -l) && $(echo "$latency < 50" | bc -l) )); then
                echo -e "${YELLOW}$trunk latency is higher than normal but acceptable ($latency ms).${NC}"
            else
                echo -e "${RED}$trunk latency is high ($latency ms), potential issue!${NC}"
            fi
        else
            echo -e "$trunk at $ip is UNREACHABLE"
            echo -e "Ping failed for $ip. Full ping output:\n$ping_output"
        fi
    done

    echo -e "${GREEN}Latency test completed. This should always show up!${NC}"
    read -p "Press Enter to continue..."
}
# Function for advanced call tools
advanced_call_tools() {
    while true; do
        clear
        echo -e "${BLUE}==== Advanced Call Tools ====${NC}"
        echo "1. Show Active Channels"
        echo "2. Show Call Statistics"
        echo "3. Monitor Call Quality"
        echo "4. Back to Main Menu"
        
        read -p "Choose option [1-4]: " subchoice
        
        case $subchoice in
            1)
                echo -e "${YELLOW}Active Channels:${NC}"
                sudo asterisk -rx "core show channels verbose"
                read -p "Press Enter to continue..."
                ;;
            2)
                echo -e "${YELLOW}Call Statistics:${NC}"
                sudo asterisk -rx "core show calls"
                sudo asterisk -rx "core show channels count"
                read -p "Press Enter to continue..."
                ;;
            3)
                echo -e "${YELLOW}Call Quality Metrics:${NC}"
                sudo asterisk -rx "sip show channelstats"
                read -p "Press Enter to continue..."
                ;;
            4)
                break
                ;;
            *)
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}
#---------------------------------------------------------------------
# Function for the main menu
main_menu() {
    while true; do
        clear
        # Print Logo
        print_logo
        # Header with improved design
        echo -e "${BLUE}========================================${NC}"
        echo -e "${GREEN}==== Asterisk Troubleshooter Menu ====${NC}"
        echo -e "${BLUE}========================================${NC}"
        
        echo -e "\n${YELLOW}1.${NC} Check SIP Status - Verify the status of SIP trunks."
        echo -e "${YELLOW}2.${NC} Monitor Trunk Status - Check the status and call counts for SIP trunks."
        echo -e "${YELLOW}3.${NC} Check Codecs - Check available codecs for SIP communication."
        echo -e "${YELLOW}4.${NC} Audio Diagnostics - Test and troubleshoot audio issues."
        echo -e "${YELLOW}5.${NC} Enable SIP Debug - Enable SIP debug to monitor SIP traffic."
        echo -e "${YELLOW}6.${NC} Force Re-registration - Force SIP devices to re-register."
        echo -e "${YELLOW}7.${NC} Test Firewall Ports - Check if required firewall ports are open."
        echo -e "${YELLOW}8.${NC} Advanced Call Tools - Access advanced tools for troubleshooting calls."
        echo -e "${YELLOW}9.${NC} Check Latency - Check if any SIP trunk has high latency."        
        echo -e "${YELLOW}10.${NC} Exit - Exit the troubleshooting tool."        
        echo -e "\n${BLUE}========================================${NC}"

        read -p "Choose option [1-9]: " choice

        case $choice in
            1) check_sip_status ;;
            2) monitor_trunk_status ;;
            3) check_codecs ;;
            4) audio_diagnostics ;;
            5) enable_sip_debug ;;
            6) force_reregistration ;;
            7) test_firewall_ports ;;
            8) advanced_call_tools ;;
            9)  test_latency ;;
            10)                echo -e "${GREEN}Exiting... Goodbye!${NC}" 
                exit 0 
                ;;
            *) 
                echo -e "${RED}Invalid option! Please choose between 1-9.${NC}" 
                sleep 1 
                ;;
        esac
    done
}

# Call the function
main_menu


