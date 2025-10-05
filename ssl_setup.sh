!/bin/bash
# Setup Let's Encrypt SSL on Nginx
# Works on Ubuntu/Debian-based systems

set -e


# -----------------------------
# Set Variables
# -----------------------------
DOMAINS=("devops.peteroyelegbin.com.ng" "www.devops.peteroyelegbin.com.ng")     # Domains & subdomains
EMAIL="info@peteroyelegbin.com.ng"                                              # Let's Encrypt email


# -----------------------------
# Install Dependencies
# -----------------------------
echo "[+] Updating system and installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx certbot python3-certbot-nginx ufw


# -----------------------------
# Configure Firewall (if UFW enabled)
# -----------------------------
if command -v ufw >/dev/null 2>&1; then
  echo "[+] Allowing Nginx Full profile in firewall..."
  sudo ufw allow 'Nginx Full'
fi


# -----------------------------
# Prepare domain strings
# -----------------------------
CERTBOT_DOMAINS=$(printf " -d %s" "${DOMAINS[@]}")


# Reload nginx
sudo nginx -t && sudo systemctl reload nginx


# -----------------------------
# Obtain Let's Encrypt SSL Certificate
# -----------------------------
echo "[+] Requesting Let's Encrypt SSL certificate for: ${DOMAINS[*]}"
sudo certbot --nginx $CERTBOT_DOMAINS --email "$EMAIL" --agree-tos --non-interactive


# -----------------------------
# Setup Auto Renewal
# -----------------------------
echo "[+] Setting up auto-renewal..."
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer


echo "[✓] SSL setup complete for: ${DOMAINS[*]}"