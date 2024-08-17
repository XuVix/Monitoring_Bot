import psutil
import time
import re
import schedule
from telegram import Bot, ParseMode
from telegram.ext.updater import Request
from config import BOT_TOKEN, CHAT_ID, SERVER_NAME, DELAY, PERCENTAGE, LOG_STATUS, HTTP_PROXY

lsdt_sent, lsdt_recv = 0, 0

def parse_proxy_url(proxy_url: str) -> tuple[str, str | None, str | None]:
    """
    Regex pattern to match and capture the username, password, and the rest of the proxy URL
    Args:
        proxy_url (str): pass raw proxy url and process it

    Returns:
        tuple[str, str | None, str | None]
    """
    pattern = re.compile(r'http://(?:(?P<username>[^:]+):(?P<password>[^@]+)@)?(?P<proxy_url>.*)')
    match = pattern.match(proxy_url)

    if match:
        proxy_details = match.groupdict()
        return proxy_details['proxy_url'], proxy_details.get('username'), proxy_details.get('password')
    return proxy_url, None, None

# added HTTP Proxy support
if HTTP_PROXY:
    proxy_url, PROXY_USERNAME, PROXY_PASSWORD = parse_proxy_url(HTTP_PROXY)
    
    if PROXY_USERNAME and PROXY_PASSWORD:
        request = Request(proxy_url=f"http://{proxy_url}",
                          urllib3_proxy_kwargs={
                              'username': PROXY_USERNAME,
                              'password': PROXY_PASSWORD,
                          })
    else:
        request = Request(proxy_url=HTTP_PROXY)

    bot = Bot(token=BOT_TOKEN, request=request)
else:
    bot = Bot(token=BOT_TOKEN)

L_STATUS = "---"
if LOG_STATUS == 1:
    L_STATUS = "Log"
elif LOG_STATUS == 2:
    L_STATUS = "Warn"
elif LOG_STATUS == 3:
    L_STATUS = "Log-Warn"

def format_size(size_in_mb):
    return f"{size_in_mb / 1024:.2f}GB" if size_in_mb >= 1024 else f"{size_in_mb:.2f}MB"

def get_network_usage():
    global last_net_io
    net_io = psutil.net_io_counters()
    
    dt_sent = (net_io.bytes_sent - last_net_io.bytes_sent) / (1024 * 1024)
    dt_recv = (net_io.bytes_recv - last_net_io.bytes_recv) / (1024 * 1024)
    
    last_net_io = net_io
    
    return dt_sent, dt_recv

def send_network_usage():
    global lsdt_sent, lsdt_recv, L_STATUS
    dt_sent, dt_recv = get_network_usage()
    
    sent_diff = 100 * ((dt_sent - lsdt_sent) / dt_sent) if lsdt_sent != 0 else 0
    recv_diff = 100 * ((dt_recv - lsdt_recv) / dt_recv) if lsdt_recv != 0 else 0

    lsdt_sent, lsdt_recv = dt_sent, dt_recv

    dt_sent_str = format_size(dt_sent)
    dt_recv_str = format_size(dt_recv)

    message = (
        f"‼️ #Warning\n"
        f"`{SERVER_NAME}`\n"
        f"➖➖➖➖➖➖➖➖➖➖\n"
        f"ULoad : `{dt_sent_str}`  `{sent_diff:.2f}%`\n"
        f"DLoad : `{dt_recv_str}`  `{recv_diff:.2f}%`\n"
        f"➖➖➖➖➖➖➖➖➖➖\n"
        f"`[{DELAY} min]`  `[{PERCENTAGE}%]`  `[{L_STATUS}]`\n"
    )
    
    if LOG_STATUS in [2, 3] and (sent_diff <= PERCENTAGE or recv_diff <= PERCENTAGE):
        bot.send_message(CHAT_ID, message, parse_mode=ParseMode.MARKDOWN)
    elif LOG_STATUS in [1, 3]:
        message = (
            f"`{SERVER_NAME}`\n"
            f"➖➖➖➖➖➖➖➖➖➖\n"
            f"ULoad : `{dt_sent_str}`  \n"
            f"DLoad : `{dt_recv_str}`  \n"
            f"➖➖➖➖➖➖➖➖➖➖\n"
            f"`[{DELAY} min]` `[{L_STATUS}]`\n"
        )
        bot.send_message(CHAT_ID, message, parse_mode=ParseMode.MARKDOWN)

def main():
    global last_net_io
    last_net_io = psutil.net_io_counters()

    message = (
        f"`{SERVER_NAME}`\n"
        f"- DELAY: `{DELAY} min`\n"
        f"- PERCENTAGE: `{PERCENTAGE} %`\n"
        f"- Log Status: `{L_STATUS}`"
    )
    bot.send_message(CHAT_ID, message, parse_mode=ParseMode.MARKDOWN)

    schedule.every(DELAY).minutes.do(send_network_usage)

    while True:
        schedule.run_pending()
        time.sleep(1)

if __name__ == "__main__":
    main()
