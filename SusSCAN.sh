#!/bin/bash
# Usage: ./SusSCAN.sh <target>
# Example: ./SusSCAN.sh 192.168.216.121

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <target>"
  exit 1
fi

target="$1"

# Custom highlight function
highlight() {
    RESET="\033[0m"
    CYAN="\033[36m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    MAGENTA="\033[35m"
    RED="\033[31m"
    BLUE="\033[34m"

    # Check if input is provided
    if [ -t 0 ] && [ $# -eq 0 ]; then
        echo "Usage: "
        echo "1. highlight < file"
        echo "2. <command> | highlight"
        return 1
    fi

    awk -v RESET="$RESET" -v CYAN="$CYAN" -v GREEN="$GREEN" -v YELLOW="$YELLOW" -v MAGENTA="$MAGENTA" -v RED="$RED" -v BLUE="$BLUE" '
        {
            # Highlight IPv4 addresses
            gsub(/([0-9]{1,3}\.){3}[0-9]{1,3}/, GREEN "&" RESET)

            # Highlight IPv6 addresses
            gsub(/([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}/, MAGENTA "&" RESET)

            # Highlight netmask
            gsub(/netmask [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/, YELLOW "&" RESET)

            # Highlight URLs
            gsub(/(https?|ftp|ftps|sftp|ssh|telnet|file|git):\/\/[^ \t\n\r\f\v<>"]+|(www\.)?([a-zA-Z0-9_-]+\.[a-zA-Z]{2,6})(\/\S*)?/, BLUE "&" RESET)

            # Highlight domains with ports (stop at space or punctuation)
            gsub(/^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$/, MAGENTA "&" RESET)

            # Highlight ports (assuming common formats)
            gsub(/[0-9]+\/tcp|udp/, GREEN "&" RESET)

            # Highlight important script details (e.g., title, category)
            gsub(/[a-zA-Z0-9-]+:\s/, CYAN "&" RESET)

            # Highlight text inside parentheses
            gsub(/\([^)]+\)/, YELLOW "&" RESET)

            # HTML tags and attribute highlighting
            {
                gsub(/<[^<>]+>/, RED "&" RESET)
                gsub(/ [a-zA-Z-]+="[^"]*?+"/, GREEN "&" RESET)
                gsub(/"[^"]*?+/, YELLOW "&" RESET)
            }

            print
        }
    '
}
export -f highlight

# ANSI escape codes for pink (light magenta) and reset.
pink="\033[95m"
reset="\033[0m"

#########################
# 1. Full TCP Scan (-p-)
#########################
tmpfile=$(mktemp)

echo -e "${pink}========================================================${reset}"
echo -e "${pink}Running full TCP scan (-p-) on $target${reset}"
echo -e "${pink}========================================================${reset}"
nmap --min-rate 4500 --max-rtt-timeout 1500ms -p- -Pn -vv "$target" -oN "$tmpfile" | highlight

# Extract open TCP port lines (e.g., "80/tcp   open  http") and filter out duplicates.
open_port_lines=$(grep -E '^[0-9]+/tcp[[:space:]]+open' "$tmpfile" | sort -u)
if [ -z "$open_port_lines" ]; then
  echo "No open TCP ports found on $target."
  rm "$tmpfile"
  exit 0
fi

# Build a comma-separated list of unique open TCP port numbers with no spaces.
open_ports=$(echo "$open_port_lines" | awk '{print $1}' | sed 's/\/tcp//' | sort -u | paste -sd, - | tr -d ' ')
rm "$tmpfile"

#########################
# 2. UDP Scan (-sU)
#########################
udp_tmpfile=$(mktemp)

echo -e "${pink}========================================================${reset}"
echo -e "${pink}Running UDP scan (-sU) on $target${reset}"
echo -e "${pink}========================================================${reset}"
nmap --min-rate 4500 --max-rtt-timeout 1500ms -sU -Pn --top-ports=20 -vv "$target" -oN "$udp_tmpfile"

# Filter UDP open port lines (ignoring "filtered" ones)
udp_open_lines=$(grep -E '^[0-9]+/udp[[:space:]]+open' "$udp_tmpfile" | sort -u)
if [ -z "$udp_open_lines" ]; then
  echo "No open UDP ports found on $target (filtered results skipped)."
else
  echo "$udp_open_lines" | highlight
fi

# Build a comma-separated list of open UDP ports (if any)
udp_open_ports=$(echo "$udp_open_lines" | awk '{print $1}' | sed 's/\/udp//' | sort -u | paste -sd, - | tr -d ' ')
rm "$udp_tmpfile"

#########################
# 3. Final TCP Scan (-sCV)
#########################
echo -e "${pink}========================================================${reset}"
echo -e "${pink}Running final TCP scan (-sCV) on ports: $open_ports${reset}"
echo -e "${pink}========================================================${reset}"
nmap -sCV -Pn -p "$open_ports" "$target" | highlight

#########################
# 4. Final UDP Scan (-sC, -sV, -sU)
#########################
if [ -n "$udp_open_ports" ]; then
  echo -e "${pink}========================================================${reset}"
  echo -e "${pink}Running final UDP scan (-sC, -sV, -sU) on ports: $udp_open_ports${reset}"
  echo -e "${pink}========================================================${reset}"
  nmap -sC -sV -sU -Pn -p "$udp_open_ports" "$target" | highlight
fi
