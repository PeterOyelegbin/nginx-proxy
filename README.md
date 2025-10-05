# NGINX Reverse Proxy & Load Balancer Setup
This guide covers setting up NGINX as a reverse proxy with SSL termination and as a load balancer.

## Table of Contents
- [Overview](#overview)
- [Use Cases Comparison](#use-cases-comparison)
- [Installation](#installation)
- [Load Balancer and Reverse Proxy Configuration](#load-balancer-and-reverse-proxy-configuration)
- [SSL Configuration](#ssl-configuration)
- [Test Configuration](#test-configuration)

---
## Overview
**Reverse Proxy**
A reverse proxy sits between clients and backend servers, forwarding client requests to appropriate backend servers and returning the server's response to the client.

**Load Balancer**
A load balancer distributes incoming network traffic across multiple backend servers to ensure no single server becomes overwhelmed.

## Use Cases Comparison
| Aspect | Reverse Proxy | Load Balancer |
|--------|---------------|---------------|
| **Primary Purpose** | Request routing, SSL termination, caching | Traffic distribution across multiple servers |
| **Server Count** | Can work with single or multiple backends | Always multiple backend servers |
| **SSL Handling** | Terminates SSL at proxy level | Can terminate SSL or pass through |
| **Caching** | Often used for content caching | Less focused on caching |
| **Health Checks** | Optional | Essential for monitoring backend servers |
| **Use Case** | Single app with multiple services, API gateway | Horizontal scaling, high availability |

---
## Installation
- Ubuntu/Debian
```bash
sudo apt update
sudo apt install nginx -y
```

- CentOS/RHEL
```bash
sudo yum update
sudo yum install epel-release -y
sudo yum install nginx -y
```

- Enable and Start NGINX
```bash
sudo systemctl enable nginx
sudo systemctl start nginx
```

---
## Load Balancer and Reverse Proxy Configuration
- Sample configuration for Load Balancer and Reverse Proxy
```nginx
# /etc/nginx/nginx.conf
http {
    # Load balancer
    upstream load_balancer {
        #least_conn;
        server 52.56.247.113 max_fails=3 fail_timeout=30s;
        server 13.42.102.8 max_fails=3 fail_timeout=30s;

        # Backup servers (used when all active are down)
        server 192.168.1.13 backup;
    }

    # Different backend services (microservices)
    upstream apache_server {
        server 52.56.247.113;
    }

    upstream nginx_server {
        server 13.42.102.8;
    }

    server {
        listen 80;
        server_name devops.peteroyelegbin.com.ng www.devops.peteroyelegbin.com.ng;

        # Load Balancer
        location / {
            proxy_pass http://load_balancer;

            # Let's Encrypt verification (will be added automatically)
            location /.well-known/acme-challenge/ {
                root /var/www/html;
            }

            # Health check endpoint
            location /health {
                access_log off;
                return 200 "healthy\n";
                add_header Content-Type text/plain;
            }
        }

        # Service 1 - /apache/*
        location /apache/ {
            proxy_pass http://apache_server/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Service 2 - /nginx/*
        location /nginx2/ {
            proxy_pass http://nginx_server/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Security headers
            proxy_hide_header X-Powered-By;
            add_header X-Proxy-Server nginx;
    
            # CORS handling
            add_header Access-Control-Allow-Origin *;
        }
    }
}
```

---
## SSL Configuration
Using Let's Encrypt (Certbot)

- Install Certbot
```bash
# Ubuntu/Debian
sudo apt install -y certbot python3-certbot-nginx

# CentOS/RHEL
sudo yum install -y certbot python3-certbot-nginx
```

- Obtain SSL Certificate
```bash
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

- Setup Auto Renewal
```bash
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

---
## Firewall Configure (if UFW enabled)
- Install UFW
```bash
sudo apt install -y ufw
```

- Allowing Nginx Full profile in firewall
```bash
sudo ufw allow 'Nginx Full'
```

---
## Test Configuration
- Test nginx configuration
```bash
sudo nginx -t
```

- Reload NGINX
```bash
sudo systemctl reload nginx
```

---
## Common Proxy Parameters File (Optional)
- Create a reusable proxy parameters file:
```nginx
# /etc/nginx/proxy_params
proxy_set_header Host $http_host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Forwarded-Port $server_port;

proxy_connect_timeout 30s;
proxy_send_timeout 30s;
proxy_read_timeout 30s;

proxy_buffering on;
proxy_buffer_size 4k;
proxy_buffers 8 4k;
```

---
## Monitoring and Logging
- Access Log Format
```nginx
log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                '$status $body_bytes_sent "$http_referer" '
                '"$http_user_agent" "$http_x_forwarded_for" '
                'proxy: $upstream_addr time: $request_time';

access_log /var/log/nginx/access.log main;
```

- Status Monitoring
```nginx
location /nginx-status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    deny all;
}
```

---
## Security Considerations
- **Rate Limiting**:
```nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

location /api/ {
    limit_req zone=api burst=20 nodelay;
    proxy_pass http://backend;
}
```

- **IP Restrictions**:
```nginx
location /admin/ {
    allow 192.168.1.0/24;
    deny all;
    proxy_pass http://backend;
}
```

This setup provides a comprehensive foundation for using NGINX as both a reverse proxy and load balancer with SSL support. Choose the configuration that best fits your specific use case and scale accordingly.
