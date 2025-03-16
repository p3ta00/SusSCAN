# SusSCAN

This repository contains a Bash script that performs multiple Nmap scans on a target IP address and highlights the output using a custom AWK-based highlighting function. The script is designed for reconnaissance and penetration testing (only use it on networks you are authorized to scan).

## Features

- **Multiple Scan Types**:  
  - **Full TCP Scan (-p-)**: Scans all TCP ports and extracts open ports.
  - **UDP Scan (-sU)**: Scans the top 20 UDP ports.
  - **Final Aggressive TCP Scan (-A)**: Performs an aggressive scan (OS detection, version detection, script scanning, and traceroute) on the discovered open TCP ports.
- **Custom Output Highlighting**:  
  A built-in `highlight()` function colorizes the output for readability. It highlights IPv4/IPv6 addresses, netmasks, URLs, ports, and more.
- **Colorized Headers**:  
  Header lines (scan separators and descriptions) are printed in pink for easy identification.

## Requirements

- **Nmap** (version 7.95 or later)

*No additional dependencies are required since the highlighting functionality is built into the script.*

> **Disclaimer**: Use this tool only on systems/networks you are authorized to scan. Unauthorized scanning is illegal and unethical.

## Usage

1. **Clone the repository:**

    ```bash
    git clone https://github.com/p3ta00/SusSCAN.git
    cd SusSCAN
    ```

2. **Make the script executable:**

    ```bash
    chmod +x SusSCAN.sh
    ```

3. **Run the script with a target IP address or hostname:**

    ```bash
    ./SusSCAN.sh 192.168.216.121
    ```
4. **Make it executable:**
   ```
   chmod +x SusSCAN.sh && sudo cp SusSCAN.sh /usr/local/bin/better_map
   ```
   
   The script will perform the following scans sequentially:
   - **Full TCP Scan (-p-)**: Scans all TCP ports and extracts open ports.
   - **UDP Scan (-sU)**: Scans the top 20 UDP ports.
   - **Final Aggressive TCP Scan (-A)**: Scans the discovered open TCP ports using the `-A` option.

## How It Works

1. **Full TCP Scan (-p-):**
   - Runs a full TCP scan using Nmap with performance options.
   - Saves output to a temporary file.
   - Extracts unique lines showing open TCP ports (e.g., `80/tcp   open  http`), prints them in green, and builds a comma-separated list for the final scan.

2. **UDP Scan (-sU):**
   - Scans the top 20 UDP ports on the target.
   - Output is colorized using the custom highlight function.

3. **Final Aggressive TCP Scan (-A):**
   - Uses Nmap’s `-A` option (OS detection, version detection, script scanning, and traceroute) on the discovered open ports.

4. **Custom Highlighting:**
   - The script contains an embedded `highlight()` function that uses AWK to apply ANSI colors to matching text patterns (IPv4/IPv6, URLs, ports, etc.), making the output more readable.

## License
