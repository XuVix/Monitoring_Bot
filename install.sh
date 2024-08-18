#!/bin/bash

colors=( "\033[1;31m" "\033[1;35m" "\033[1;92m" "\033[38;5;46m" "\033[1;38;5;208m" "\033[1;36m" "\033[0m" )
red=${colors[0]} pink=${colors[1]} green=${colors[2]} spring=${colors[3]} orange=${colors[4]} cyan=${colors[5]} reset=${colors[6]}
print() { echo -e "${cyan}$1${reset}"; }
error() { echo -e "${red}✗ $1${reset}"; }
success() { echo -e "${spring}✓ $1${reset}"; }
log() { echo -e "${green}! $1${reset}"; }
input() { read -p "$(echo -e "${orange}▶ $1${reset}")" "$2"; }
confirm() { read -p "$(echo -e "\n${pink}Press any key to continue...${reset}")"; }

trap 'echo -e "\n"; error "Script interrupted! Contact: @XuVix"; exit 1' SIGINT

SERVICE_NAME="Monitoring_Bot.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
INSTALL_DIR="/opt/Monitoring_Bot"

menu() {
    while true; do
        print "\t@XuVix MonitoringBot [0.1.0]"
        print "——————————————————————————————————————"
        if check_installation; then
            print "1) Reinstall"
            print "2) Status"
            print "3) Restart"
            print "4) Uninstall"
            print "5) Show logs"
        else
            print "1) Install"
        fi
        print "0) Exit"
        print ""
        input "Enter your option number: " option
        clear
        case $option in
            1) start_install_bot ;;
            2) 
                if check_installation; then
                    status_bot
                else
                    error "Bot is not installed!"
                fi 
                ;;
            3) 
                if check_installation; then
                    restart_bot
                else
                    error "Bot is not installed!"
                fi 
                ;;
            4) 
                if check_installation; then
                    start_uninstall_bot
                else
                    error "Bot is not installed!"
                fi 
                ;;
            5) 
                if check_installation; then
                    show_logs
                else
                    error "Bot is not installed!"
                fi 
                ;;
            0) error "Thank you for using @XuVix script. Goodbye!" && exit 0 ;;
            *) error "Invalid option, Please select a valid option!" ;;
        esac
    done
}

start_install_bot() {
    check_needs
    get_bot_info
    get_server_name
    get_monotoring_delay
    get_log_status
    setup_bot
}

setup_bot() {
    cleanup_old_installation
    install_dependencies
    setup_python_environment
    download_script_and_create_config
    setup_systemd_service
    success "Telegram Monitoring Bot is now installed and running for ${name}"
    log "DELAY=${delay} min, LOG_STATUS=${log_status}, PERCENTAGE=${percentage}"
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
    install_dependencies
}

get_bot_info() {
    print "To use Telegram, you need to provide a bot token and a chat ID.\n"
    while true; do
        input "Enter the bot token: " bot_token
        if [[ -z "$bot_token" ]]; then
            error "Bot token cannot be empty!"
        elif [[ ! "$bot_token" =~ ^[0-9]+:[a-zA-Z0-9_-]{35}$ ]]; then
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
            response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://api.telegram.org/bot$bot_token/sendMessage" -d chat_id="$chat_id" -d text="Hi Bro! (test bot)")
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

    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt-get"
        PKG_UPDATE="$PKG_MANAGER update -y"
        PKG_INSTALL="$PKG_MANAGER install -y"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        PKG_UPDATE="$PKG_MANAGER check-update"
        PKG_INSTALL="$PKG_MANAGER install -y"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        PKG_UPDATE="$PKG_MANAGER check-update"
        PKG_INSTALL="$PKG_MANAGER install -y"
    else
        error "No supported package manager found. Please install packages manually."
        exit 1
    fi

    log "Checking for system updates..."
    $PKG_UPDATE || true
}

install_dependencies() {
    log "Updating package lists and installing dependencies..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-venv python3-pip curl
}

setup_python_environment() {
    log "Creating installation directory and setting up virtual environment..."
    sudo mkdir -p $INSTALL_DIR
    python3 -m venv $INSTALL_DIR/venv
    source $INSTALL_DIR/venv/bin/activate
    log "Upgrading pip and installing Python packages..."
    pip install --upgrade pip
    pip uninstall -y python-telegram-bot || true
    pip install "python-telegram-bot==13.7" "psutil>=5.9.0" "schedule>=1.1.0" "urllib3==1.26.15"
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