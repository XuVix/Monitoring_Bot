# Monitoring_Bot
a Simple Bot to Monitoring Data Usage

# install
 ```
curl -sL https://raw.githubusercontent.com/XuVix/Monitoring_Bot/main/install.sh | sudo bash -s -- <YourBotToken> <YourChatID> <YourServerName>
 ```
# Full install
 ```
curl -sL https://raw.githubusercontent.com/XuVix/Monitoring_Bot/main/install.sh | sudo bash -s -- <YourBotToken> <YourChatID> <YourServerName> <Delay> <Log_Status> <Percentage>

 ```
# status
 ```
sudo systemctl status Monitoring_Bot.service
 ```
# Log
 ```
sudo journalctl -u Monitoring_Bot.service -f
 ```
# Stop and disable the service
 ```
sudo systemctl stop Monitoring_Bot.service

sudo systemctl disable Monitoring_Bot.service

sudo rm /etc/systemd/system/Monitoring_Bot.service

sudo systemctl daemon-reload

 ```

# Remove the installation directory
 ```
sudo rm -rf /opt/Monitoring_Bot

 ```

