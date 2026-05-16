#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${DOMAIN:-opspilot.abdoamer.me}"
SITE_ROOT="${SITE_ROOT:-/var/www/opspilot}"
SERVER_NAME="${SERVER_NAME:-$DOMAIN}"
REPO_URL="${REPO_URL:-https://github.com/amer2040/portfolio.git}"
BRANCH="${BRANCH:-main}"
TMP_DIR="${TMP_DIR:-/tmp/opspilot-site}"
ENABLE_SSL="${ENABLE_SSL:-1}"
EMAIL="${EMAIL:-}"

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo bash scripts/deploy-opspilot-vps.sh"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx git rsync ca-certificates curl

rm -rf "$TMP_DIR"
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TMP_DIR"

mkdir -p "$SITE_ROOT"
rsync -a --delete "$TMP_DIR/opspilot/" "$SITE_ROOT/"
chown -R www-data:www-data "$SITE_ROOT"
find "$SITE_ROOT" -type d -exec chmod 755 {} \;
find "$SITE_ROOT" -type f -exec chmod 644 {} \;

cat > "/etc/nginx/sites-available/opspilot" <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name ${SERVER_NAME};

    root ${SITE_ROOT};
    index index.html;

    gzip on;
    gzip_comp_level 5;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/javascript application/javascript application/json image/svg+xml;

    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header X-Frame-Options "SAMEORIGIN" always;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location ~* \.(?:css|js|jpg|jpeg|gif|png|webp|svg|ico|woff2?)$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000, immutable";
        try_files \$uri =404;
    }
}
NGINX

ln -sfn /etc/nginx/sites-available/opspilot /etc/nginx/sites-enabled/opspilot
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable --now nginx
systemctl reload nginx

if [[ "$ENABLE_SSL" == "1" ]]; then
  apt-get install -y certbot python3-certbot-nginx
  if [[ -n "$EMAIL" ]]; then
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect
  else
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect
  fi
fi

rm -rf "$TMP_DIR"
echo "OpsPilot deployed to https://${DOMAIN}"
