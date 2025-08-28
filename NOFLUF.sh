#!/data/data/com.termux/files/usr/bin/bash
# Jaydaplug++ : LazyMux++ (All-in-One Intense) for Termux
# Use responsibly. Only test systems you own or have written permission for.
# Save as jaydaplugpp.sh, chmod +x jaydaplugpp.sh, ./jaydaplugpp.sh

set -euo pipefail
IFS=$'\n\t'

########## UI / Logging / Helpers ##########
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; CYAN="\033[1;36m"; RESET="\033[0m"; BOLD="\033[1m"

WORKDIR="$HOME/JaydaplugPP"
LOGDIR="$HOME/JaydaplugPP-logs"
mkdir -p "$WORKDIR" "$LOGDIR"
LOGFILE="$LOGDIR/install-$(date +%Y%m%d-%H%M%S).log"

echo_banner(){
  clear
  cat <<'EOF'
   ██████  ██    ██  █████   ██████  ██    ██
  ██      ██    ██ ██   ██ ██    ██ ██    ██
  ██      ██    ██ ███████ ██    ██ ██    ██
  ██      ██    ██ ██   ██ ██    ██ ██    ██
   ██████  ██████  ██   ██  ██████   ██████
      Jaydaplug++ — LazyMux++ (All-In-One Intense)
EOF
  echo
  echo -e "${YELLOW}Log file:${RESET} $LOGFILE"
  echo -e "${RED}LEGAL:${RESET} Only run tools on systems you own or have explicit permission to test."
  echo
}

log(){ echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"; }

spinner(){
  local pid=$1; local msg="$2"
  local delay=0.07; local spinstr='|/-\'
  printf "%s " "$msg"
  while kill -0 $pid 2>/dev/null; do
    for i in 0 1 2 3; do
      printf "%s" "${spinstr:i:1}"; sleep $delay; printf "\b"
    done
  done
  printf " \n"
}

safe_pkg_install(){
  for pkg in "$@"; do
    if command -v "$pkg" >/dev/null 2>&1; then
      printf "${GREEN}[FOUND]${RESET} %s\n" "$pkg"
    else
      printf "${YELLOW}[INSTALL]${RESET} %s\n" "$pkg"
      pkg install -y "$pkg" >>"$LOGFILE" 2>&1 || { printf "${RED}[WARN] Failed pkg: %s (continuing)${RESET}\n" "$pkg"; }
    fi
  done
}

git_clone_retry(){
  local repo="$1"; local dest="$2"; local tries=3; local attempt=1
  if [ -d "$dest" ]; then
    printf "${CYAN}[SKIP]${RESET} %s exists\n" "$dest"
    return 0
  fi
  while [ $attempt -le $tries ]; do
    printf "${CYAN}[CLONE]${RESET} %s -> %s (try %d/%d)\n" "$repo" "$dest" "$attempt" "$tries"
    git clone --depth 1 "$repo" "$dest" >>"$LOGFILE" 2>&1 && return 0
    attempt=$((attempt+1)); sleep 2
  done
  printf "${RED}[ERROR]${RESET} failed to clone %s after %d tries\n" "$repo" "$tries" | tee -a "$LOGFILE"
  return 1
}

go_install_retry(){
  local pkg="$1"; local tries=3; local attempt=1
  mkdir -p "$HOME/go/bin"; export PATH="$HOME/go/bin:$PATH"
  while [ $attempt -le $tries ]; do
    printf "${CYAN}[GO]${RESET} go install %s (try %d/%d)\n" "$pkg" "$attempt" "$tries"
    GOPATH="$HOME/go" PATH="$HOME/go/bin:$PATH" go install -v "$pkg" >>"$LOGFILE" 2>&1 && return 0
    attempt=$((attempt+1)); sleep 2
  done
  printf "${RED}[ERROR]${RESET} go install failed: %s\n" "$pkg" | tee -a "$LOGFILE"
  return 1
}

########## Menu UI ##########
print_menu(){
  cat <<EOF
${BOLD}Select categories (single number or multiple separated by spaces):${RESET}

┌────┬────────────────────────────────────────────┬──────────────────────────────┐
│ ID │ Category                                   │ Key Tools (examples)         │
├────┼────────────────────────────────────────────┼──────────────────────────────┤
│ 1  │ OSINT & Recon                              │ theHarvester, amass, subfinder│
│ 2  │ Pentest / Exploitation Frameworks          │ metasploit, sqlmap, routersploit│
│ 3  │ Active Scanning & Fuzzing                  │ masscan, naabu, nuclei, ffuf  │
│ 4  │ Web Tools & Scanners                       │ dirsearch, nikto, wafw00f     │
│ 5  │ Passwords & Wordlists                       │ hydra, john, hashcat, SecLists│
│ 6  │ Network/Wireless/Poisoning                  │ aircrack-ng, bettercap, responder│
│ 7  │ Post-Exploitation & Tunneling               │ weevely, ngrok, chisel, frp   │
│ 8  │ Collections & Payloads                      │ SecLists, PayloadsAllTheThings, exploitdb│
│ 9  │ Dev & Cloud Tools                            │ rclone, yt-dlp, aria2, tmux  │
│ 10 │ Privacy & Onion / Tor Tools                 │ tor, onionshare, torbrowser (headless)│
├────┼────────────────────────────────────────────┼──────────────────────────────┤
│ a  │ Install ALL (EVERYTHING in this script)     │ All of the above              │
│ q  │ Quit                                        │ Exit                          │
└────┴────────────────────────────────────────────┴──────────────────────────────┘

EOF
  echo "Tip: after installing Go tools run: export PATH=\$PATH:\$HOME/go/bin"
}

########## Installers ##########
install_core_prereqs(){
  log "Installing core prerequisites..."
  safe_pkg_install git curl wget unzip proot nano python nodejs golang make clang perl ruby rust unzip
  # extras: UI helpers
  safe_pkg_install dialog fzf
  mkdir -p "$WORKDIR"/tools
}

install_osint(){
  log "Installing OSINT & Recon tools..."
  safe_pkg_install nmap dnsutils masscan
  # Go-based project discovery tools
  go_install_retry github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest || true
  go_install_retry github.com/projectdiscovery/httpx/cmd/httpx@latest || true
  go_install_retry github.com/projectdiscovery/naabu/v2/cmd/naabu@latest || true
  git_clone_retry https://github.com/laramies/theHarvester.git "$WORKDIR/tools/theHarvester"
  git_clone_retry https://github.com/OWASP/Amass.git "$WORKDIR/tools/amass"
  git_clone_retry https://github.com/tomnomnom/assetfinder.git "$WORKDIR/tools/assetfinder"
  git_clone_retry https://github.com/sherlock-project/sherlock.git "$WORKDIR/tools/sherlock"
  git_clone_retry https://github.com/blechschmidt/massdns.git "$WORKDIR/tools/massdns" || true
  log "OSINT installs finished."
}

install_pentest(){
  log "Installing Pentest & Exploitation frameworks..."
  # metasploit via unstable-repo package (termux)
  pkg install -y unstable-repo >>"$LOGFILE" 2>&1 || true
  safe_pkg_install metasploit
  # Classic tools
  git_clone_retry https://github.com/sqlmapproject/sqlmap.git "$WORKDIR/tools/sqlmap"
  git_clone_retry https://github.com/threat9/routersploit.git "$WORKDIR/tools/routersploit"
  git_clone_retry https://github.com/commixproject/commix.git "$WORKDIR/tools/commix"
  # Note: avoid automated exploit execution; this is install only.
  log "Pentest frameworks installed."
}

install_active_fuzzing(){
  log "Installing Active Scanning & Fuzzing..."
  safe_pkg_install nmap
  go_install_retry github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest || true
  go_install_retry github.com/ffuf/ffuf@latest || true
  go_install_retry github.com/OJ/gobuster/v3@latest || true
  git_clone_retry https://github.com/projectdiscovery/nuclei-templates.git "$WORKDIR/tools/nuclei-templates" || true
  git_clone_retry https://github.com/maurosoria/dirsearch.git "$WORKDIR/tools/dirsearch"
  log "Scanning & fuzzing tools installed."
}

install_webtools(){
  log "Installing Web tools & scanners..."
  safe_pkg_install nikto wafw00f whatweb
  git_clone_retry https://github.com/s0md3v/XSStrike.git "$WORKDIR/tools/xsstrike"
  git_clone_retry https://github.com/maurosoria/dirsearch.git "$WORKDIR/tools/dirsearch" || true
  log "Web tools installed."
}

install_passwords(){
  log "Installing Password attack & wordlist tools..."
  safe_pkg_install hydra john hashcat crunch
  git_clone_retry https://github.com/danielmiessler/SecLists.git "$WORKDIR/tools/SecLists"
  # Attempt rockyou download (may be large)
  if [ ! -f "$HOME/rockyou.txt" ]; then
    log "Attempting rockyou small mirror download (if available)..."
    (wget -q -O /tmp/rockyou.txt.gz https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt || true) && (gunzip -c /tmp/rockyou.txt.gz > "$HOME/rockyou.txt" 2>/dev/null || true)
    rm -f /tmp/rockyou.txt.gz
  fi
  log "Password tools installed."
}

install_network_wireless(){
  log "Installing Network/Wireless tools..."
  safe_pkg_install aircrack-ng bettercap tcpdump mitmproxy
  git_clone_retry https://github.com/SpiderLabs/Responder.git "$WORKDIR/tools/responder" || true
  log "Network/Wireless tools installed."
}

install_postex_tunnel(){
  log "Installing Post-exploitation & tunneling tools..."
  safe_pkg_install wget unzip socat
  git_clone_retry https://github.com/epinna/weevely3.git "$WORKDIR/tools/weevely3"
  # ngrok (arm)
  if [ ! -f "$HOME/ngrok" ]; then
    log "Attempting ngrok ARM download"
    wget -q -O /tmp/ngrok.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip || true
    unzip -o /tmp/ngrok.zip -d "$HOME" >/dev/null 2>&1 || true
    rm -f /tmp/ngrok.zip
  fi
  go_install_retry github.com/jpillora/chisel@latest || true
  log "Post-exploitation & tunneling tools installed."
}

install_collections(){
  log "Installing Collections & Payloads..."
  git_clone_retry https://github.com/swisskyrepo/PayloadsAllTheThings.git "$WORKDIR/tools/PayloadsAllTheThings"
  git_clone_retry https://github.com/offensive-security/exploitdb.git "$WORKDIR/tools/exploitdb"
  log "Collections installed."
}

install_dev_cloud(){
  log "Installing Dev & Cloud tools..."
  safe_pkg_install rclone aria2 tmux jq
  pkg install -y python ffmpeg >/dev/null 2>&1 || true
  # yt-dlp for downloading (legal use only)
  python -m pip install --user yt-dlp >>"$LOGFILE" 2>&1 || true
  # rclone config hint file
  echo "# rclone configs go here" > "$WORKDIR/rclone-readme.txt"
  log "Dev & Cloud tools installed."
}

install_privacy_onion(){
  log "Installing Tor & privacy tools..."
  safe_pkg_install tor torsocks
  git_clone_retry https://github.com/micahflee/torbrowser-launcher.git "$WORKDIR/tools/torbrowser-launcher" || true
  git_clone_retry https://github.com/micahflee/onionshare.git "$WORKDIR/tools/onionshare" || true
  log "Privacy & Tor tools installed."
}

install_extras_intense(){
  log "Installing extra intense tools (OSINT, more scanners)..."
  go_install_retry github.com/projectdiscovery/chaos-client/cmd/chaos@latest || true
  go_install_retry github.com/haccer/subjack@latest || true
  git_clone_retry https://github.com/jaeles-project/jaeles.git "$WORKDIR/tools/jaeles" || true
  git_clone_retry https://github.com/ffuf/ffuf.git "$WORKDIR/tools/ffuf" || true
  log "Intense extras installed."
}

install_all(){
  log "=== STARTING FULL INSTALL ==="
  install_core_prereqs &
  PID=$!; spinner $PID "Core prerequisites..."
  wait $PID

  install_osint &
  PID=$!; spinner $PID "OSINT..."
  wait $PID

  install_active_fuzzing &
  PID=$!; spinner $PID "Active scanning & fuzzing..."
  wait $PID

  install_webtools &
  PID=$!; spinner $PID "Web tools..."
  wait $PID

  install_pentest &
  PID=$!; spinner $PID "Pentest frameworks..."
  wait $PID

  install_passwords &
  PID=$!; spinner $PID "Password tools..."
  wait $PID

  install_network_wireless &
  PID=$!; spinner $PID "Network & wireless..."
  wait $PID

  install_postex_tunnel &
  PID=$!; spinner $PID "Post-exploitation..."
  wait $PID

  install_collections &
  PID=$!; spinner $PID "Collections..."
  wait $PID

  install_dev_cloud &
  PID=$!; spinner $PID "Dev & cloud..."
  wait $PID

  install_privacy_onion &
  PID=$!; spinner $PID "Privacy & onion..."
  wait $PID

  install_extras_intense &
  PID=$!; spinner $PID "Intense extras..."
  wait $PID

  log "=== FULL INSTALL FINISHED ==="
  echo -e "${GREEN}All selected installs complete. Check log: ${RESET}$LOGFILE"
}

########## Main flow ##########
main(){
  echo_banner
  print_menu
  read -p $'\e[1;34mChoose (e.g. "1 3" or "a" or "q"): \e[0m' user_in || { echo "No input"; exit 1; }
  if [ -z "$user_in" ]; then echo "No selection. Exiting."; exit 1; fi
  if [[ "$user_in" =~ ^[qQ]$ ]]; then echo "Bye."; exit 0; fi
  if [[ "$user_in" =~ ^[aA]$ ]]; then
    echo -e "${YELLOW}Installing EVERYTHING (this can take many hours and lots of space).${RESET}"
    install_all
    exit 0
  fi

  for token in $user_in; do
    case "$token" in
      1) install_osint ;;
      2) install_pentest ;;
      3) install_active_fuzzing ;;
      4) install_webtools ;;
      5) install_passwords ;;
      6) install_network_wireless ;;
      7) install_postex_tunnel ;;
      8) install_collections ;;
      9) install_dev_cloud ;;
      10) install_privacy_onion ;;
      *) echo -e "${YELLOW}Skipping invalid token: $token${RESET}" ;;
    esac
  done

  echo -e "${GREEN}Selected installs complete. Logs: ${RESET}$LOGFILE"
}

main "$@"
