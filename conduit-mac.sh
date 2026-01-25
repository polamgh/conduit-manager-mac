#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════╗
# ║             🚀 PSIPHON CONDUIT (macOS)                    ║
# ╚═══════════════════════════════════════════════════════════════╝

# --- CONFIGURATION ---
CONTAINER_NAME="conduit-mac"
# Updated to release d8522a8 (Critical Update)
IMAGE="ghcr.io/ssmirr/conduit/conduit:d8522a8"
VOLUME_NAME="conduit-data"

# --- COLORS ---
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- UTILS ---
print_header() {
    clear
    echo -e "${CYAN}"
    echo "  ██████╗ ██████╗ ███╗   ██╗██████╗ ██╗   ██╗██╗████████╗"
    echo " ██╔════╝██╔═══██╗████╗  ██║██╔══██╗██║   ██║██║╚══██╔══╝"
    echo " ██║     ██║   ██║██╔██╗ ██║██║  ██║██║   ██║██║   ██║   "
    echo " ██║     ██║   ██║██║╚██╗██║██║  ██║██║   ██║██║   ██║   "
    echo " ╚██████╗╚██████╔╝██║ ╚████║██████╔╝╚██████╔╝██║   ██║   "
    echo "  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝  ╚═════╝ ╚═╝   ╚═╝   "
    echo -e "              ${YELLOW}macOS Professional Edition${CYAN}                  "
    echo -e "${NC}"
}

check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}[ERROR] Docker is NOT running!${NC}"
        echo "Please start Docker Desktop and try again."
        exit 1
    fi
}

# --- SMART START LOGIC ---
smart_start() {
    print_header
    
    # 1. Check if container exists at all
    if ! docker ps -a | grep -q "$CONTAINER_NAME"; then
        echo -e "${BLUE}▶ FIRST TIME SETUP${NC}"
        echo "-----------------------------------"
        install_new
        return
    fi

    # 2. Check if it is currently running
    if docker ps | grep -q "$CONTAINER_NAME"; then
        # STATUS: RUNNING -> RESTART
        echo -e "${YELLOW}Status: Running${NC}"
        echo -e "${BLUE}Action: Restarting Service...${NC}"
        docker restart $CONTAINER_NAME > /dev/null
        echo -e "${GREEN}✔ Service Restarted Successfully.${NC}"
        sleep 2
    else
        # STATUS: STOPPED -> START
        echo -e "${RED}Status: Stopped${NC}"
        echo -e "${BLUE}Action: Starting Service...${NC}"
        docker start $CONTAINER_NAME > /dev/null
        echo -e "${GREEN}✔ Service Started Successfully.${NC}"
        sleep 2
    fi
}

# --- INSTALLATION (First Time or Reconfigure) ---
install_new() {
    echo ""
    # Default set to 200 as recommended by developer (Psiphon default is 50 which is too low)
    read -p "Maximum Clients [Default: 200]: " MAX_CLIENTS
    MAX_CLIENTS=${MAX_CLIENTS:-200}
    
    # Updated text to mention -1 for unlimited
    read -p "Bandwidth Limit (Mbps) [Default: 5, Enter -1 for Unlimited]: " BANDWIDTH
    BANDWIDTH=${BANDWIDTH:-5}

    echo ""
    echo -e "${YELLOW}Deploying container (ver: d8522a8)...${NC}"
    
    docker rm -f $CONTAINER_NAME 2>/dev/null || true
    
    # Pull the new image first to ensure we have the update
    docker pull $IMAGE > /dev/null
    
    # Passed flags explicitly as required by the new update
    docker run -d \
        --name $CONTAINER_NAME \
        --restart unless-stopped \
        -v $VOLUME_NAME:/home/conduit/data \
        --network host \
        $IMAGE \
        start --max-clients "$MAX_CLIENTS" --bandwidth "$BANDWIDTH" -v > /dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✔ Installation Complete & Started!${NC}"
        echo ""
        read -n 1 -s -r -p "Press any key to return..."
    else
        echo -e "${RED}✘ Installation Failed.${NC}"
        read -n 1 -s -r -p "Press any key to continue..."
    fi
}

stop_service() {
    echo -e "${YELLOW}Stopping Conduit...${NC}"
    docker stop $CONTAINER_NAME > /dev/null 2>&1
    echo -e "${GREEN}✔ Service stopped.${NC}"
    sleep 1
}

view_dashboard() {
    trap "break" SIGINT
    
    while true; do
        print_header
        echo -e "${BOLD}LIVE DASHBOARD${NC} (Press ${YELLOW}Ctrl+C${NC} to Exit)"
        echo "══════════════════════════════════════════════════════"
        
        if docker ps | grep -q "$CONTAINER_NAME"; then
            # Stats fetching
            DOCKER_STATS=$(docker stats --no-stream --format "{{.CPUPerc}}|{{.MemUsage}}" $CONTAINER_NAME)
            CPU=$(echo "$DOCKER_STATS" | cut -d'|' -f1)
            RAM=$(echo "$DOCKER_STATS" | cut -d'|' -f2)
            
            # Fetch Logs
            LOG_LINE=$(docker logs --tail 50 $CONTAINER_NAME 2>&1 | grep "\[STATS\]" | tail -n 1)
            
            if [[ -n "$LOG_LINE" ]]; then
                CONN=$(echo "$LOG_LINE" | sed -n 's/.*Connected:[[:space:]]*\([0-9]*\).*/\1/p')
                UP=$(echo "$LOG_LINE" | sed -n 's/.*Up:[[:space:]]*\([^|]*\).*/\1/p' | tr -d ' ')
                DOWN=$(echo "$LOG_LINE" | sed -n 's/.*Down:[[:space:]]*\([^|]*\).*/\1/p' | tr -d ' ')
            else
                CONN="0"
                UP="0B"
                DOWN="0B"
            fi
            
            UPTIME=$(docker ps -f name=$CONTAINER_NAME --format '{{.Status}}')

            echo -e " STATUS:      ${GREEN}● ONLINE${NC}"
            echo -e " UPTIME:      $UPTIME"
            echo "──────────────────────────────────────────────────────"
            printf " %-15s | %-15s \n" "RESOURCES" "TRAFFIC"
            echo "──────────────────────────────────────────────────────"
            printf " CPU: ${YELLOW}%-9s${NC} | Users: ${GREEN}%-9s${NC} \n" "$CPU" "$CONN"
            printf " RAM: ${YELLOW}%-9s${NC} | Up:    ${CYAN}%-9s${NC} \n" "$RAM" "$UP"
            printf "              | Down:  ${CYAN}%-9s${NC} \n" "$DOWN"
            echo "══════════════════════════════════════════════════════"
            echo -e "${YELLOW}Refreshing every 10 seconds...${NC}"
        else
            echo -e " STATUS:      ${RED}● OFFLINE${NC}"
            echo "──────────────────────────────────────────────────────"
            echo -e " Service is not running."
            echo " Press 1 to Start."
            echo "══════════════════════════════════════════════════════"
        fi
        
        sleep 10
    done
    trap - SIGINT
}

view_logs() {
    clear
    echo -e "${CYAN}Streaming Logs (Press Ctrl+C to Exit)...${NC}"
    echo "------------------------------------------------"
    docker logs -f --tail 100 $CONTAINER_NAME
}

# --- MAIN MENU ---

check_docker

while true; do
    print_header
    echo -e "${BOLD}MAIN MENU${NC}"
    echo " 1. ▶  Start / Restart (Smart)"
    echo " 2. ⏹  Stop Service"
    echo " 3. 📊 Open Live Dashboard"
    echo " 4. 📜 View Raw Logs"
    echo " 5. ⚙  Reconfigure (Re-install)"
    echo " 0. 🚪 Exit"
    echo ""
    read -p " Select option [0-5]: " option

    case $option in
        1) smart_start ;;
        2) stop_service ;;
        3) view_dashboard ;;
        4) view_logs ;;
        5) print_header; echo -e "${BLUE}▶ RECONFIGURATION${NC}"; install_new ;;
        0) echo -e "${CYAN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
