# OpsPilot VPS Deployment

Target domain: `opspilot.abdoamer.me`

## DNS

Create an `A` record:

- Host: `opspilot`
- Value: your Google VPS public IPv4
- Proxy/CDN: off at first if using Cloudflare, until SSL is issued

## First deploy on the VPS

```bash
sudo apt-get update
sudo apt-get install -y curl
curl -fsSL https://raw.githubusercontent.com/amer2040/portfolio/main/scripts/deploy-opspilot-vps.sh -o deploy-opspilot-vps.sh
sudo DOMAIN=opspilot.abdoamer.me EMAIL=you@example.com bash deploy-opspilot-vps.sh
```

If you do not want SSL yet, run:

```bash
sudo DOMAIN=opspilot.abdoamer.me ENABLE_SSL=0 bash deploy-opspilot-vps.sh
```

## Update deploy later

Re-run the same script. It clones the latest `main`, syncs only the `opspilot/` directory into `/var/www/opspilot`, tests Nginx, and reloads it.

## VPS notes

The page is static HTML/CSS/JS, so it is suitable for a 2-core / 1GB RAM VPS with 2GB swap. Nginx serves it with gzip and long cache headers for static assets.
