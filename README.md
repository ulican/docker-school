# Exercise 1 – Static Web Page in Docker

Lightweight NGINX container that serves a custom **index.html**. Runs in WSL 2 on port **8080** so there’s no clash with Rancher Desktop / Traefik.

---

[ Browser ]
    |
    | 1. User requests: http://www.schoolofdevops.ro:8081
    v
[ nginx-proxy container ]
    - listens on port 8081 (host → container 80)
    - checks header: Host = www.schoolofdevops.ro
    - knows from VIRTUAL_HOST that traffic should go to `sod-app`
    |
    | 2. proxy_pass request to `sod-app`
    v
[ sod-app container ]
    - NGINX listens on port 80
    - reads config from default.conf/nginx.conf
    - finds file /usr/share/nginx/html/index.html
    |
    | 3. responds with HTML
    v
[ nginx-proxy container ]
    - receives response from `sod-app`
    - forwards it back to client
    |
    v
[ Browser ]
    - displays <h1>Welcome to School of DevOps!</h1>


## 1  Quick view

| Item            | Value                     |
| --------------- | ------------------------- |
| **Base image**  | `alpine:3.20` + `nginx`   |
| **Built image** | `sod-static:latest`       |
| **Host port**   | **8080** → container `80` |

---

## 2  Folder layout

```
docker-school/
└─ app/
   ├─ Dockerfile      # build recipe
   ├─ index.html      # welcome page
   ├─ default.conf    # NGINX server block
   └─ nginx.conf      # minimal main config
```

---

## 3  How to run (30 sec)

```bash
# Build once
cd app
docker build -t sod-static .

# Run / restart when needed
docker run -d --name sod -p 8080:80 sod-static

# Test
curl http://localhost:8080
#  → <h1>Welcome to School of DevOps!</h1>
```

---

## 4  Common hiccups & fixes

| Symptom                            | Fix                                                                 |
| ---------------------------------- | ------------------------------------------------------------------- |
| `Dockerfile cannot be empty`       | File name was **DockerFile** → renamed to **Dockerfile**.           |
| `unknown instruction: CMD["nginx"` | Added space → `CMD ["nginx", …]`.                                   |
| `server directive is not allowed…` | Added custom **nginx.conf** with `http { include conf.d/*.conf; }`. |
| Port 80 already in use             | Traefik used it → mapped host **8080** instead.                     |

---

# Phase 2 – Run the site with **Docker Compose** + **nginx‑proxy**

Simple demo of a reverse‑proxy stack, ready in under 2 minutes.

---

## 1 ▪ Goal

Serve your **sod‑static** image via a smart front‑end (`nginx‑proxy`) so the page is reachable at:

```
http://www.schoolofdevops.ro:8081
```

---

## 2 ▪ Prerequisites

| What you already have | Why                                              |
| --------------------- | ------------------------------------------------ |
| Image `sod-static`    | Built in Phase 1 (Alpine + NGINX + `index.html`) |
| Docker Compose v2     | Orchestrates multiple containers                 |
| Line in `/etc/hosts`  | Local DNS alias → `127.0.0.1`                    |

```text
127.0.0.1   www.schoolofdevops.ro
```

---

## 3 ▪ Folder layout

```
docker-school/
├─ app/                 # Phase 1 files
└─ docker-compose.yaml  # created in Phase 2
```

---

## 4 ▪ `docker-compose.yaml`

```yaml
services:
  app:
    image: sod-static
    container_name: sod-app
    networks: [proxy-net]
    environment:
      - VIRTUAL_HOST=www.schoolofdevops.ro

  nginx-proxy:
    image: jwilder/nginx-proxy:alpine
    container_name: nginx-proxy
    ports:
      - "8081:80"   # local HTTP
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
    networks: [proxy-net]

networks:
  proxy-net:
```

---

## 5 ▪ Run & test

```bash
# start stack
docker compose up -d

# check
curl http://www.schoolofdevops.ro:8081
```

Expected output:

```html
<h1>Welcome to School of DevOps!</h1>
```

Stop everything:

```bash
docker compose down
```

---

## 6 ▪ Troubleshooting (quick)

| Symptom                               | Fix                                                                            |
| ------------------------------------- | ------------------------------------------------------------------------------ |
| `port is already allocated`           | Change mapping to `8082:80` (or another free port).                            |
| `503 Service Temporarily Unavailable` | 1) confirm line in `/etc/hosts`  2) rebuild `sod-static` ensuring `EXPOSE 80`. |

---


---
# CircleCI Integration
