# Deploying with Coolify

## Prerequisites

- A Linux server (tested target: Ubuntu 24.04, **2 vCPU / 4 GB RAM** recommended; Elasticsearch + Temporal need memory)
- [Coolify](https://coolify.io) installed on the server
- A subdomain you control, e.g. `postiz.example.com`

## 1. DNS

Create an **A record** (and AAAA if you use IPv6):

| Type | Name | Value |
|---|---|---|
| A | `postiz` | `<server IPv4>` |

Check it before continuing:

```bash
dig +short postiz.example.com
```

## 2. Create the resource

1. Coolify → **Projects → + New → Resource**
2. Choose **Public Repository** (or GitHub App for private repos) and paste this repository URL
3. Build pack: **Docker Compose**, file: `/docker-compose.yml`

## 3. Environment variables

In the resource's **Environment Variables** tab, add every variable from `.env.example`.
Generate secrets locally with `openssl rand -hex 32`.

| Variable | Production value |
|---|---|
| `POSTIZ_URL` | `https://postiz.example.com` |
| `POSTIZ_BIND` | `0.0.0.0` *(Coolify's proxy runs in its own container)* |
| `JWT_SECRET`, `POSTGRES_PASSWORD`, `TEMPORAL_DB_PASSWORD` | random 64-character hex strings |
| `POSTIZ_VERSION` | a pinned release tag instead of `latest` |

> Mark secrets as **"Is Secret / Locked"** in Coolify so they are hidden in the UI and logs.

## 4. Domain and HTTPS

On the **postiz** service set the domain to:

```
https://postiz.example.com:5000
```

The `:5000` tells Coolify's Traefik proxy which **container** port to route to. Traefik then gets a Let's Encrypt certificate automatically.

## 5. Deploy and lock down

1. Click **Deploy** and watch the logs until all services are healthy (first start takes a few minutes).
2. Open `https://postiz.example.com` and create the admin account.
3. Set `DISABLE_REGISTRATION=true` and **redeploy**.
4. Firewall: allow only `22`, `80`, `443` (plus Coolify's dashboard port if needed).

```bash
sudo ufw allow 22,80,443/tcp
sudo ufw enable
```

## Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| Login works but you are logged out immediately | `POSTIZ_URL` is `http://` or does not match the domain; Postiz needs HTTPS for its secure cookies |
| `temporal` keeps restarting | Elasticsearch not healthy yet or too little RAM; check `docker logs temporal-elasticsearch` |
| 502 Bad Gateway | Wrong port in the Coolify domain field; must be `:5000` |
| Channel connection fails with redirect error | Callback URL in the provider's developer app doesn't match `POSTIZ_URL` |
