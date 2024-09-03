#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BRIGHT_PURPLE='\033[1;35m'
ORANGE='\033[38;5;208m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' 
# Test tool

# Font styles
BOLD='\033[1m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
RESET='\033[0m'

echo -e "${BRIGHT_PURPLE}"

cat << "EOF"
+=========================================================+
|                __        __                      _      |
|    _______  __/ /_  ____/ /___  ____ ___  ____ _(_)___  |
|   / ___/ / / / __ \/ __  / __ \/ __ `__ \/ __ `/ / __ \ |
|  (__  ) /_/ / /_/ / /_/ / /_/ / / / / / / /_/ / / / / / |
| /____/\__,_/_.___/\__,_/\____/_/ /_/ /_/\__,_/_/_/ /_/  |
|         __              __                              |
|   _____/ /_  ___  _____/ /_____  _____                  |
|  / ___/ __ \/ _ \/ ___/ //_/ _ \/ ___/                  |
| / /__/ / / /  __/ /__/ ,< /  __/ /                      |
| \___/_/ /_/\___/\___/_/|_|\___/_/                       |
|                                                         |
+=========================================================+
EOF

echo
echo -e "${NC}[${RED}${BOLD}VERSION${NC}]: ${GREEN}v0.0.1${NC}"  
echo
install_package_go() {
    INSTALL_DIR="/usr/local"
    GO_TOOLS="$HOME/go/bin"
    GO_URL="https://golang.org/dl/go1.21.1.linux-amd64.tar.gz" 
    GO_TAR="go1.21.1.linux-amd64.tar.gz"

    # Ensure that /usr/local exists and is writable
    if [ ! -d "$INSTALL_DIR" ]; then
        echo "Installation directory $INSTALL_DIR does not exist."
        exit 1
    fi

    echo -e "${CYAN}Installing Go..."
    echo
    sudo wget -q --show-progress "$GO_URL" -O "/tmp/$GO_TAR"

    # Check if the download was successful
    if [ $? -ne 0 ]; then
        echo "Failed to download Go tarball."
        exit 1
    fi

    # Extracting the tar file to '/usr/local'
    echo "Extracting Go tarball..."
    sudo tar -C "$INSTALL_DIR" -xzf "/tmp/$GO_TAR"

    # Clean up the tarball
    sudo rm -rf "/tmp/$GO_TAR"
}

function install_package_subfinder(){
    echo -e "${CYAN}Installing subfinder...${NC}"
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest > /dev/null 2>&1
    echo -e "${GREEN}Successfully installed subfinder...${NC}"
}

function install_package_httpx(){
    echo -e "${CYAN}Installing httpx...${NC}"
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest > /dev/null 2>&1
    echo -e "${GREEN}Successfully installed httpx...${NC}"
}

function install_package_dig(){
    echo -e "${CYAN}Installing dig...${NC}"
    sudo apt install dnsutils > /dev/null 2>&1
    echo -e "${GREEN}Successfully installed dig...${NC}" 
}


# Usage 
if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage${NC}: $0 [domain_name]"
    exit 1
fi

missing_packages=()


# install_package_go
if command -v subfinder >/dev/null 2>&1; then
    echo -e "${BOLD}REQUIRED PACKAGE: ${GREEN}subfinder is installed ...${NC}"
else
    echo -e "${BOLD}REQUIRED PACKAGE: ${RED}subfinder is not installed.${NC}"
    missing_packages+=("subfinder")
fi

if command -v httpx >/dev/null 2>&1; then
    echo -e "${BOLD}REQUIRED PACKAGE: ${GREEN}httpx is installed ...${NC}"
else
    echo -e "${BOLD}REQUIRED PACKAGE: ${RED}httpx is not installed.${NC}"
    missing_packages+=("httpx")
fi

if command -v dig >/dev/null 2>&1; then
    echo -e "${BOLD}REQUIRED PACKAGE: ${GREEN}dig is installed ...${NC}"
else
    echo -e "${BOLD}REQUIRED PACKAGE: ${RED}dig is not installed.${NC}"
    missing_packages+=("dig")
fi

if [ "${#missing_packages[@]}" -eq 0 ]; then
    echo -e "${GREEN}All packages are present proceeding to search!"
else
    if command -v apt >/dev/null 2>&1; then
        echo -e "${YELLOW}Packages need to be installed"
        for modules in "${missing_packages[@]}"; do
            echo -e "${YELLOW}# ${RED}$modules${NC}"
        done
        echo -e "${BOLD}${YELLOW}Try this as root or You have to be admin to access this resource${NC}"
        echo -e "${BOLD}${YELLOW}If you are an admin You'll be asked to enter your password to set it as temporary PATH variable${NC}" 
        echo "Do you want to install these packages [Y/N]:"
        read install_permission

        install_permission=$(echo "$install_permission" | tr '[:lower:]' '[:upper:]')

        if [ "$install_permission" == "Y" ]; then
            if command -v go > /dev/null 2>&1; then 
                echo -e "${GREEN}Go is already installed.${NC}"

                # Adding PATH variables for subfinder and httpx
                echo 'export PATH="$PATH:/$HOME/go/bin"' >> ~/.bashrc
                export PATH="$PATH:/$HOME/go/bin"
            else 
                install_package_go

                # Adding PATH variables for go to ~/.bashrc
                echo 'export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"' >> ~/.bashrc
                export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
                echo -e "${GREEN}Go has been installed and PATH updated.${NC}"
            fi
            source ~/.bashrc

            for modules in "${missing_packages[@]}"; do
                func_name="install_package_${modules}"
                eval "${func_name}"
            done
        elif [ "$install_permission" == "N" ]; then
            echo -e "${RED}Installation aborted."
            exit 0
        else
            echo -e "${RED}Invalid input. Please enter 'Y' for Yes or 'N' for No. Process terminating.."
            exit 0
        fi
    else
        echo -e "${RED}Auto-installation available only for debian based OS. For other OS You need to install '${CYAN}subfinder${NC}' and '${CYAN}httpx${NC}' manually."
        exit 0
    fi
fi



# Check for the results folder and subfiles, if none present create them
availabledomains="./result/availabledomains.txt"
activedomains="./result/activedomains.txt"
domaininfo="./result/domaininfo.txt"

if [ ! -d "./result" ]; then
    echo "Creating './result'"
    mkdir ./result
fi

if [ ! -e "$availabledomains" ]; then
    echo "Creating './result/availabledomains.txt'"
    touch "$availabledomains"
fi

if [ ! -e "$activedomains" ]; then
    echo "Creating './result/activedomains.txt'"
    touch "$activedomains"
fi

if [ ! -e "$domaininfo" ]; then
    echo "Creating './result/domaininfo.txt'"
    touch "$domaininfo"
fi

# Check for all the available domains
echo -e "${BOLD}${BLUE}Checking for the available subdomains for: ${NC}${YELLOW}$1${NC}"
echo -e "${BOLD}${YELLOW}Please wait this may take a while..${NC}"
subfinder -d "$1" -silent > "$availabledomains"

# If the file 'availabledomains' is not empty then check for active domains
if [ -s "$availabledomains" ]; then
    echo -e "${GREEN}Got a list of subdomains${NC}"

    # Print the available domains
    echo
    echo -e "${BOLD}${CYAN}Available subdomains:${NC}"
    echo
    while IFS= read -r available_domain
    do
        echo -e "${MAGENTA}${available_domain}${NC}"
    done < "$availabledomains"
    echo
    echo -e "${BOLD}${GREEN}Checking for the active subdomains...${NC}"
    echo -e "${BOLD}${YELLOW}Please wait this may take a while..${NC}"
    httpx -l "$availabledomains" -o "$activedomains" -silent > /dev/null

    # If the file 'activedomains.txt' is not empty then check for active domains
    if [ -s "$activedomains" ]; then
        echo -e "${GREEN}Here's a list of active subdomains${NC}"

        # Printing the active domains
        echo
        echo -e "${BOLD}${CYAN}Active subdomains:${NC}"
        echo
        while IFS= read -r active_domain
        do
            echo -e "${MAGENTA}${active_domain}${NC}"
        done < "$activedomains"
    else
        echo -e "${BOLD}${RED}No active subdomains found. Terminating the process${NC}"
        exit 1
    fi
else
    echo -e "${BOLD}${RED}No available subdomains found. Terminating the process.${NC}"
    exit 1
fi

# Check the DNS records of all the active domains
while IFS= read -r domain
do
    domain=$(echo "$domain" | sed -e 's|https\?://||')

    a_record=$(dig "$domain" A +short)
    aaaa_record=$(dig "$domain" AAAA +short)
    cname_record=$(dig "$domain" CNAME +short)
    caa_record=$(dig "$domain" CAA +short)
    hinfo_record=$(dig "$domain" HINFO +short)
    txt_record=$(dig "$domain" TXT +short)
    mx_record=$(dig "$domain" MX +short)
    soa_record=$(dig "$domain" SOA +short)
    
    echo
    echo -e "${BOLD}${ORANGE}DNS records for subdomain: ${NC}${GREEN}$domain${NC}"
    echo    
    
    echo -ne "${BRIGHT_PURPLE}A record: ${NC}"
    if [ -n "$a_record" ]; then
        echo "$a_record"
        echo
    else
        echo "No A record found"
        echo
    fi

    echo -ne "${BRIGHT_PURPLE}AAAA record: ${NC}"
    if [ -n "$aaaa_record" ]; then
        echo "$aaaa_record"
        echo
    else
        echo "No AAAA record found"
        echo
    fi

    echo -ne "${BRIGHT_PURPLE}CNAME record: ${NC}"
    if [ -n "$cname_record" ]; then
        echo "$cname_record"
        echo
    else
        echo "No CNAME record found"
        echo
    fi

    echo -ne "${BRIGHT_PURPLE}CAA record: ${NC}"
    if [ -n "$caa_record" ]; then
        echo "$caa_record"
        echo
    else
        echo "No CAA record found"
        echo
    fi

    echo -ne "${BRIGHT_PURPLE}HINFO record: ${NC}"
    if [ -n "$hinfo_record" ]; then
        echo "$hinfo_record"
        echo
    else
        echo "No HINFO record found"
        echo
    fi

    echo -ne "${BRIGHT_PURPLE}TXT record: ${NC}"
    if [ -n "$txt_record" ]; then
        echo "$txt_record"
        echo
    else
        echo "No TXT record found"
        echo
    fi

    echo -ne "${BRIGHT_PURPLE}MX record: ${NC}"
    if [ -n "$mx_record" ]; then
        echo "$mx_record"
        echo
    else
        echo "No MX record found"
        echo
    fi

    echo -ne "${BRIGHT_PURPLE}SOA record: ${NC}"
    if [ -n "$soa_record" ]; then
        echo "$soa_record"
        echo
    else
        echo "No SOA record found"
        echo
    fi

done < "$activedomains"

