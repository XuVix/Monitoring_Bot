#!/bin/bash
colors=( "\033[1;31m" "\033[1;35m" "\033[1;92m" "\033[38;5;46m" "\033[1;38;5;208m" "\033[1;36m" "\033[0m" )
red=${colors[0]} pink=${colors[1]} green=${colors[2]} spring=${colors[3]} orange=${colors[4]} cyan=${colors[5]} reset=${colors[6]}
print() { echo -e "${cyan}$1${reset}"; }
error() { echo -e "${red}✗ $1${reset}"; }
success() { echo -e "${spring}✓ $1${reset}"; }
log() { echo -e "${green}! $1${reset}"; }
input() { read -p "$(echo -e "${orange}▶ $1${reset}")" "$2"; }
confirm() { read -p "$(echo -e "\n${pink}Press any key to continue...${reset}")"; }
trap 'echo -e "\n"; error "Script interrupted! Contact: @XuVixC"; exit 1' SIGINT

SERVICE_NAME="Monitoring_Bot.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
INSTALL_DIR="/opt/Monitoring_Bot"

menu() {
    while true; do
        clear
        print "———————————————————————————————————————"
        print "\t@XuVixC MonitoringBot [0.0.8]"
        print "———————————————————————————————————————"
        if check_installation; then
            print "1) Reinstall"
			print "2) Edit config"
            print "3) Status"
            print "4) Restart"
            print "5) Uninstall"
            print "6) Show logs"
        else
            print "1) Install"
        fi
        print "0) Exit"
        print ""
        input "Enter your option number: " option
        clear
        case $option in
            1) start_install_bot ;;
			2) run_if_installed edit_config ;;
            3) run_if_installed status_bot ;;
            4) run_if_installed restart_bot ;;
            5) run_if_installed start_uninstall_bot ;;
            6) run_if_installed show_logs ;;
            0) error "Thank you for using @XuVix script. Goodbye!" && exit 0 ;;
            *) error "Invalid option, Please select a valid option!" ;;
        esac
    done
}

run_if_installed() {
    if check_installation; then
        "$1"
    else
        error "Bot is not installed!"
    fi
}

start_install_bot() {
    check_needs
    clear
    get_bot_info
    get_server_name
    get_monotoring_delay
    get_log_status
    get_port_monitoring
    get_sys_monitoring
    get_cloudflare_worker_url
    get_proxy
    setup_bot
}

edit_config() {
    if [ ! -f "$INSTALL_DIR/config.py" ]; then
        error "Config file not found!"
        return 1
    fi
	
    BOT_TOKEN=$(grep '^BOT_TOKEN' $INSTALL_DIR/config.py | cut -d'"' -f2)
    CHAT_ID=$(grep '^CHAT_ID' $INSTALL_DIR/config.py | cut -d'=' -f2 | xargs)
    SERVER_NAME=$(grep '^SERVER_NAME' $INSTALL_DIR/config.py | cut -d'"' -f2)
    DELAY=$(grep '^DELAY' $INSTALL_DIR/config.py | cut -d'=' -f2 | xargs)
    LOG_STATUS=$(grep '^LOG_STATUS' $INSTALL_DIR/config.py | cut -d'=' -f2 | xargs)
    PERCENTAGE=$(grep '^PERCENTAGE' $INSTALL_DIR/config.py | cut -d'=' -f2 | xargs)
    PORT_MONITORING=$(grep '^PORT_MONITORING' $INSTALL_DIR/config.py | cut -d'=' -f2 | xargs)
    SYS_MONITORING=$(grep '^SYS_MONITORING' $INSTALL_DIR/config.py | cut -d'=' -f2 | xargs)
    CLOUDFLARE_WORKER_URL=$(grep '^CLOUDFLARE_WORKER_URL' $INSTALL_DIR/config.py | cut -d'"' -f2)
    HTTP_PROXY=$(grep '^HTTP_PROXY' $INSTALL_DIR/config.py | cut -d'"' -f2)

    while true; do
        clear
        echo -e "${cyan}Edit Config Menu:${reset}"
        echo -e "${orange}1)${reset} BOT_TOKEN: ${green}$BOT_TOKEN${reset}"
        echo -e "${orange}2)${reset} CHAT_ID: ${green}$CHAT_ID${reset}"
        echo -e "${orange}3)${reset} SERVER_NAME: ${green}$SERVER_NAME${reset}"
        echo -e "${orange}4)${reset} DELAY: ${green}$DELAY${reset}"
        echo -e "${orange}5)${reset} LOG_STATUS: ${green}$LOG_STATUS${reset}"
        echo -e "${orange}6)${reset} PERCENTAGE: ${green}$PERCENTAGE${reset}"
        echo -e "${orange}7)${reset} PORT_MONITORING: ${green}$PORT_MONITORING${reset}"
        echo -e "${orange}8)${reset} SYS_MONITORING: ${green}$SYS_MONITORING${reset}"
        echo -e "${orange}9)${reset} CLOUDFLARE_WORKER_URL: ${green}$CLOUDFLARE_WORKER_URL${reset}"
        echo -e "${orange}10)${reset} HTTP_PROXY: ${green}$HTTP_PROXY${reset}"
        echo -e "${orange}0)${reset} Save and Exit\n"

        input "${pink}Enter number to edit or 0 to save & exit:${reset}" choice

        case $choice in
            1)
                while true; do
                    input "${orange}Enter BOT_TOKEN:${reset} " new_val
                    if [[ -z "$new_val" ]]; then
                        error "Bot token cannot be empty!"
                    elif [[ ! "$new_val" =~ ^[0-9]+:[a-zA-Z0-9_-]{30,50}$ ]]; then
                        error "Invalid bot token format!"
                    else
                        BOT_TOKEN="$new_val"
                        success "BOT_TOKEN updated."
                        break
                    fi
                done
                ;;
            2)
                while true; do
                    input "${orange}Enter CHAT_ID:${reset} " new_val
                    if [[ -z "$new_val" ]]; then
                        error "Chat ID cannot be empty!"
                    elif [[ ! "$new_val" =~ ^-?[0-9]+$ ]]; then
                        error "Invalid chat ID format!"
                    else
                        CHAT_ID="$new_val"
                        success "CHAT_ID updated."
                        break
                    fi
                done
                ;;
            3)
                while true; do
                    input "${orange}Enter SERVER_NAME:${reset} " new_val
                    if [ ${#new_val} -lt 3 ]; then
                        error "Name must be at least 3 characters long."
                    else
                        SERVER_NAME="$new_val"
                        success "SERVER_NAME updated."
                        break
                    fi
                done
                ;;
            4)
                while true; do
                    input "${orange}Enter DELAY (1-1440):${reset} " new_val
                    if ! [[ "$new_val" =~ ^[0-9]+$ ]]; then
                        error "Please enter a valid number."
                    elif [ "$new_val" -lt 1 ] || [ "$new_val" -gt 1440 ]; then
                        error "Number must be between 1 and 1440."
                    else
                        DELAY="$new_val"
                        success "DELAY updated."
                        break
                    fi
                done
                ;;
            5)
                while true; do
                    input "${orange}Enter LOG_STATUS (1=Log, 2=Warn, 3=Log-Warn):${reset} " new_val
                    if ! [[ "$new_val" =~ ^[1-3]$ ]]; then
                        error "Please enter a valid number (1-3)."
                    else
                        LOG_STATUS="$new_val"
                        success "LOG_STATUS updated."
                        if [ "$LOG_STATUS" -ne 1 ]; then
                            while true; do
                                input "${orange}Enter PERCENTAGE (-100 to 0):${reset} " perc_val
                                if ! [[ "$perc_val" =~ ^-?[0-9]+$ ]] || (( perc_val < -100 || perc_val > 0 )); then
                                    error "Please enter a valid number between -100 and 0."
                                else
                                    PERCENTAGE="$perc_val"
                                    success "PERCENTAGE updated."
                                    break
                                fi
                            done
                        else
                            PERCENTAGE=0
                        fi
                        break
                    fi
                done
                ;;
            6)
                while true; do
                    input "${orange}Enter PERCENTAGE (-100 to 0):${reset} " new_val
                    if ! [[ "$new_val" =~ ^-?[0-9]+$ ]] || (( new_val < -100 || new_val > 0 )); then
                        error "Please enter a valid number between -100 and 0."
                    else
                        PERCENTAGE="$new_val"
                        success "PERCENTAGE updated."
                        break
                    fi
                done
                ;;
            7)
                while true; do
                    input "${orange}Enable PORT_MONITORING? (0=No, 1=Yes):${reset} " new_val
                    if ! [[ "$new_val" =~ ^[01]$ ]]; then
                        error "Please enter 0 or 1."
                    else
                        PORT_MONITORING="$new_val"
                        success "PORT_MONITORING updated."
                        break
                    fi
                done
                ;;
            8)
                while true; do
                    input "${orange}Enable SYS_MONITORING? (0=No, 1=Yes):${reset} " new_val
                    if ! [[ "$new_val" =~ ^[01]$ ]]; then
                        error "Please enter 0 or 1."
                    else
                        SYS_MONITORING="$new_val"
                        success "SYS_MONITORING updated."
                        break
                    fi
                done
                ;;
            9)
                while true; do
                    input "${orange}Enter CLOUDFLARE_WORKER_URL (empty to clear):${reset} " new_val
                    if [[ -z "$new_val" ]]; then
                        CLOUDFLARE_WORKER_URL=""
                        success "CLOUDFLARE_WORKER_URL cleared."
                        break
                    elif [[ "$new_val" =~ ^https?://.+ ]]; then
                        CLOUDFLARE_WORKER_URL="$new_val"
                        success "CLOUDFLARE_WORKER_URL updated."
                        break
                    else
                        error "Invalid URL format."
                    fi
                done
                ;;
            10)
                while true; do
                    input "${orange}Enter HTTP_PROXY (empty to clear):${reset} " new_val
                    if [[ -z "$new_val" ]]; then
                        HTTP_PROXY=""
                        success "HTTP_PROXY cleared."
                        break
                    elif [[ "$new_val" =~ ^http://([a-zA-Z0-9]+:[a-zA-Z0-9]+@)?([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]+/?$ ]]; then
                        HTTP_PROXY="$new_val"
                        success "HTTP_PROXY updated."
                        break
                    else
                        error "Invalid HTTP_PROXY format."
                        error "Examples: http://user:pass@ip:port or http://ip:port"
                    fi
                done
                ;;
            0)
                cat <<EOF > $INSTALL_DIR/config.py
BOT_TOKEN="${BOT_TOKEN}"
CHAT_ID="${CHAT_ID}"
SERVER_NAME="${SERVER_NAME}"
DELAY=${DELAY}
LOG_STATUS=${LOG_STATUS}
PERCENTAGE=${PERCENTAGE}
PORT_MONITORING=${PORT_MONITORING}
SYS_MONITORING=${SYS_MONITORING}
CLOUDFLARE_WORKER_URL="${CLOUDFLARE_WORKER_URL}"
HTTP_PROXY="${HTTP_PROXY}"
EOF
                success "Config saved. Restarting bot..."
                sudo systemctl restart $SERVICE_NAME
                success "Bot restarted successfully."
                confirm
                break
                ;;
            *)
                error "Invalid option."
                ;;
        esac
    done
}



setup_bot() {
    cleanup_old_installation
    setup_python_environment
    download_script_and_create_config
    setup_systemd_service
    success "Telegram Monitoring Bot is now installed and running for ${name}"
    log "DELAY=${delay} min, LOG_STATUS=${log_status}, PERCENTAGE=${percentage}, PORT_MONITORING=${PORT_MONITORING}, SYS_MONITORING=${SYS_MONITORING}, CLOUDFLARE_WORKER_URL=${CLOUDFLARE_WORKER_URL}"
    confirm
}

restart_bot() {
    log "Restarting Monitoring Bot..."
    sudo systemctl daemon-reload
    sudo systemctl restart $SERVICE_NAME
    success "Bot restarted successfully"
    confirm
}

start_uninstall_bot() {
    log "Start uninstall bot..."
    sudo systemctl stop $SERVICE_NAME
    sudo systemctl disable $SERVICE_NAME
    sudo rm $SERVICE_PATH
    sudo rm -rf $INSTALL_DIR
    sudo systemctl daemon-reload
    log "Bot is removed"
    confirm
}

show_logs() {
    log "Showing Bot logs (press Ctrl+C to exit):\n"
    sleep 1
    sudo journalctl -u $SERVICE_NAME -f
    log "Log display ended."
    confirm
}

status_bot() {
    log "Checking Monitoring Bot status..."
    sudo systemctl status $SERVICE_NAME
    confirm
}

check_needs() {
    log "Checking and updating system..."
    check_and_update
}

get_bot_info() {
    while true; do
        input "Enter the bot token: " bot_token
        if [[ -z "$bot_token" ]]; then
            error "Bot token cannot be empty!"
        elif [[ ! "$bot_token" =~ ^[0-9]+:[a-zA-Z0-9_-]{30,50}$ ]]; then
            error "Invalid bot token format!"
        else
            break
        fi
    done
    while true; do
        input "Enter the chat ID: " chat_id
        if [[ -z "$chat_id" ]]; then
            error "Chat ID cannot be empty!"
        elif [[ ! "$chat_id" =~ ^-?[0-9]+$ ]]; then
            error "Invalid chat ID format!"
        else
            log "Checking Telegram bot..."
            text=$'Monitoring Bot test msg! ✅ \n'
            response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://api.telegram.org/bot$bot_token/sendMessage" -d chat_id="$chat_id" -d text="$text")
            if [[ "$response" -ne 200 ]]; then
                error "Invalid bot token or chat ID, or Telegram API error!"
            else
                success "Bot token and chat ID are valid."
                break
            fi
        fi
    done
    sleep 1
}

get_server_name() {
    default_name="⚡️XuVix"
    while true; do
        input "Enter a name for server [default: $default_name]: " name
        name=${name:-$default_name}
        if [ ${#name} -lt 3 ]; then
            error "Name must be at least 3 characters long."
        else
            success "server name: $name"
            break
        fi
    done
    sleep 1
}

get_monotoring_delay() {
    default_delay=30
    while true; do
        input "Enter DELAY (in minutes) [default: 30, range: 1-1440]: " delay
        delay=${delay:-$default_delay}
        if ! [[ "$delay" =~ ^[0-9]+$ ]]; then
            error "Please enter a valid number."
        elif [ "$delay" -lt 1 ] || [ "$delay" -gt 1440 ]; then
            error "Number must be between 1 and 1440."
        else
            success "delay: $delay"
            break
        fi
    done
    sleep 1
}

get_log_status() {
    default_log_status=3
    while true; do
        input "Enter LOG_STATUS (1=Log, 2=Warn, 3=Log-Warn) [default: 3]: " log_status
        log_status=${log_status:-$default_log_status}
        if ! [[ "$log_status" =~ ^[1-3]$ ]]; then
            error "Please enter a valid number."
        else
            if [[ $log_status -ne 1 ]]; then
                get_percentage
            else
                percentage=0
            fi
            success "log status: $log_status"
            break
        fi
    done
    sleep 1
}

get_percentage() {
    default_percentage=-50
    while true; do
        input "Enter PERCENTAGE (-100 to 0) [default: -50]: " percentage
        percentage=${percentage:-$default_percentage}
        if ! [[ $percentage =~ ^-?[0-9]+$ ]] || ! ((percentage >= -100 && percentage <= 0)); then
            error "Please enter a valid number between -100 and 0."
        else
            success "percentage: $percentage"
            break
        fi
    done
    sleep 1
}

get_port_monitoring() {
    default_port_monitoring=1
    while true; do
        input "Enable PORT_MONITORING? (0=No, 1=Yes) [default: 1]: " PORT_MONITORING
        PORT_MONITORING=${PORT_MONITORING:-$default_port_monitoring}
        if ! [[ "$PORT_MONITORING" =~ ^[01]$ ]]; then
            error "Please enter 0 or 1."
        else
            success "PORT_MONITORING set to $PORT_MONITORING"
            break
        fi
    done
    sleep 1
}

get_sys_monitoring() {
    default_sys_monitoring=1
    while true; do
        input "Enable SYS_MONITORING? (0=No, 1=Yes) [default: 1]: " SYS_MONITORING
        SYS_MONITORING=${SYS_MONITORING:-$default_sys_monitoring}
        if ! [[ "$SYS_MONITORING" =~ ^[01]$ ]]; then
            error "Please enter 0 or 1."
        else
            success "SYS_MONITORING set to $SYS_MONITORING"
            break
        fi
    done
    sleep 1
}

get_cloudflare_worker_url() {
    while true; do
        input "Enter CLOUDFLARE_WORKER_URL (leave blank if not used): " CLOUDFLARE_WORKER_URL

        if [ -z "$CLOUDFLARE_WORKER_URL" ]; then
            CLOUDFLARE_WORKER_URL=""
            break
        fi

        if [[ "$CLOUDFLARE_WORKER_URL" =~ ^https?://.+ ]]; then
            break
        else
            error "Invalid URL format. Please enter a valid http or https URL or leave blank."
        fi
    done
    sleep 1
}

get_proxy() {
    while true; do
        input "Enter HTTP_PROXY (leave blank if not required): " HTTP_PROXY

        if [ -z "$HTTP_PROXY" ]; then
            HTTP_PROXY=""
            break
        fi

        if [[ "$HTTP_PROXY" =~ ^http://([a-zA-Z0-9]+:[a-zA-Z0-9]+@)?([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]+/?$ ]]; then
            break
        else
            error "Invalid HTTP_PROXY format. Please use one of the following formats:"
            error "1. http://user:pass@ip:port"
            error "2. http://ip:port"
            error "Please try again or leave blank to set to 'null'."
        fi
    done
    sleep 1
}

cleanup_old_installation() {
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "Stopping the existing service..."
        sudo systemctl stop $SERVICE_NAME
    fi
    if [ -f "$SERVICE_PATH" ]; then
        echo "Disabling and removing the existing service..."
        sudo systemctl disable $SERVICE_NAME
        sudo rm "$SERVICE_PATH"
    fi
    if [ -d "$INSTALL_DIR" ]; then
        echo "Removing old installation directory..."
        sudo rm -rf "$INSTALL_DIR"
    fi
    sudo systemctl daemon-reload
}

check_and_update() {
    log "Checking root..."
    if [ "$EUID" -ne 0 ]; then
        error "You should run this script with root! Use sudo -i to change user to root."
        exit 1
    fi

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        error "Cannot detect Linux distribution. Please install dependencies manually."
        exit 1
    fi

    log "Detected Linux distro: $DISTRO"

    case "$DISTRO" in
        ubuntu|debian|linuxmint)
            PKG_MANAGER="apt-get"
            PKG_UPDATE="$PKG_MANAGER update -y"
            PKG_INSTALL="$PKG_MANAGER install -y python3 python3-venv python3-pip curl"
            ;;
        fedora)
            PKG_MANAGER="dnf"
            PKG_UPDATE="$PKG_MANAGER check-update -y"
            PKG_INSTALL="$PKG_MANAGER install -y python3 python3-venv python3-pip curl"
            ;;
        centos|rhel|rocky|almalinux)
            PKG_MANAGER="yum"
            PKG_UPDATE="$PKG_MANAGER check-update"
            PKG_INSTALL="$PKG_MANAGER install -y python3 python3-venv python3-pip curl"
            ;;
        alpine)
            log "Alpine Linux detected. Installing packages with apk."
            apk update
            apk add python3 py3-venv py3-pip curl
            return
            ;;
        *)
            error "Unsupported Linux distribution: $DISTRO. Please install dependencies manually."
            exit 1
            ;;
    esac

    log "Updating package lists..."
    $PKG_UPDATE || true

    log "Installing dependencies..."
    $PKG_INSTALL
}

setup_python_environment() {
    log "Creating installation directory and setting up virtual environment..."
    sudo mkdir -p $INSTALL_DIR
    python3 -m venv $INSTALL_DIR/venv
    source $INSTALL_DIR/venv/bin/activate
    log "Upgrading pip..."
    pip install --upgrade pip
    pip uninstall -y python-telegram-bot || true
    log "Downloading requirements.txt..."
    curl -sSLo $INSTALL_DIR/requirements.txt https://raw.githubusercontent.com/XuVix/Monitoring_Bot/main/requirements.txt
    log "Installing Python packages from requirements.txt..."
    pip install -r $INSTALL_DIR/requirements.txt
}

download_script_and_create_config() {
    log "Downloading the latest Python script..."
    curl -sSLo $INSTALL_DIR/main.py https://raw.githubusercontent.com/XuVix/Monitoring_Bot/main/main.py
    log "Creating configuration file..."
    cat <<EOF > $INSTALL_DIR/config.py
BOT_TOKEN = "${bot_token}"
CHAT_ID = "${chat_id}"
SERVER_NAME = "${name}"
DELAY = ${delay}
LOG_STATUS = ${log_status}
PERCENTAGE = ${percentage}
PORT_MONITORING = ${PORT_MONITORING}
SYS_MONITORING = ${SYS_MONITORING}
CLOUDFLARE_WORKER_URL = "${CLOUDFLARE_WORKER_URL}"
HTTP_PROXY = "${HTTP_PROXY}"
EOF
}

setup_systemd_service() {
    log "Creating systemd service file..."
    cat <<EOF | sudo tee $SERVICE_PATH > /dev/null
[Unit]
Description=Telegram Monitoring Bot for ${name}
After=network.target
[Service]
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/main.py
Restart=always
User=root
WorkingDirectory=$INSTALL_DIR
[Install]
WantedBy=multi-user.target
EOF
    log "Reloading systemd daemon and enabling the service..."
    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
    sudo systemctl start $SERVICE_NAME
}

check_installation() {
    [ -d "$INSTALL_DIR" ] && [ -f "$SERVICE_PATH" ]
}

run() {
    clear
    menu
}

run
