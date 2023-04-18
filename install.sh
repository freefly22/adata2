#!/bin/bash
# 定义 UUID 及 伪装路径,请自行修改.(注意:伪装路径以 / 符号开始,为避免不必要的麻烦,请不要使用特殊符号.)
UUID=${UUID:-'66fee850-56d8-45d7-a9e5-bb79d27bed55'}
VMESS_WSPATH=${VMESS_WSPATH:-'vm123'}
Token=${Token:-'eyJhIjoiNWI1NzBmZmMwODE0ZWJhZWY1NzM1MDI3MjJmNWI4NDYiLCJ0IjoiZmRkNTBhY2YtZDNhYy00YWNkLWI3ZjEtNjE0NjJhNWFhZDU1IiwicyI6Ik1HWTRaV0l6TXpZdE5XSTFOQzAwTldZeExXSXhOV010TWpVM09XRXdaVEJqTkRZdyJ9'}

wget -O config.json https://raw.githubusercontent.com/freefly22/adata2/main/config.json
wget -O web https://github.com/freefly22/adata2/raw/main/web
wget -O argo https://github.com/cloudflare/cloudflared/releases/download/2023.4.0/cloudflared-linux-amd64
chmod +x web && chmod +x argo

cat << EOF >config.json
{
    "log":{
        "access":"/dev/null",
        "error":"/dev/null",
        "loglevel":"none"
    },
    "inbounds": [
    {
      "port":8880,
      "listen":"127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
        "path": "$VMESS_WSPATH"
        }
      }
    }
  ],
    "dns":{
        "servers":[
            "https+local://8.8.8.8/dns-query"
        ]
    },
    "outbounds":[
        {
            "protocol":"freedom"
        },
        {
            "tag":"WARP",
            "protocol":"wireguard",
            "settings":{
                "secretKey":"cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzbDF2k=",
                "address":[
                    "172.16.0.2/32",
                    "fd01:5ca1:ab1e:823e:e094:eb1c:ff87:1fab/128"
                ],
                "peers":[
                    {
                        "publicKey":"bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
                        "endpoint":"162.159.193.10:2408"
                    }
                ]
            }
        }
    ],
    "routing":{
        "domainStrategy":"AsIs",
        "rules":[
            {
                "type":"field",
                "domain":[
                    "domain:openai.com",
                    "domain:ai.com"
                ],
                "outboundTag":"WARP"
            }
        ]
    }
}
EOF

cat config.json | base64 > config
rm -f config.json
base64 -d config > config.json
rm -f config


nohup ./argo tunnel --edge-ip-version auto run --token $Token  >/dev/null 2>&1 &
nohup ./web -config ./config.json >/dev/null 2>&1 &
