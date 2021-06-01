# rolling release version with http to https redirect and tls v12 minimum
variable "dcs" {
  type = list(string)
  default = ["dc1", "devel", "prod"]
}

job "traefik" {
  datacenters  = var.dcs
  namespace    = "system"
  type         = "system"

  # rolling release
  update {
    max_parallel      = 2
    health_check      = "checks"
    min_healthy_time  = "30s"
    healthy_deadline  = "5m"
    auto_revert       = true
  }

  group "traefik" {
    count = 1


    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:latest"
        network_mode = "host"

        volumes = [
          "local/traefik.yaml:/etc/traefik/traefik.yaml"
        ]
      #    "/opt/certs:/certs"
      #  ]

        # Docker special options for logging
        logging {
            type = "loki"
            config {
                loki-batch-size =  "400"
                loki-url = "http://loki.fejk.net/loki/api/v1/push"
            }
        }

      }

      template {
        data = <<EOF
---

# TODO: https://www.smarthomebeginner.com/cloudflare-settings-for-traefik-docker/

entryPoints:
  http:
    address: ":80"
# Cloudflare does https proxy  
#    http:
#      redirections:
#        entryPoint:
#          to: https
#          scheme: https
#          #permanent: true
    forwardedHeaders:
      insecure: true

# Cloudflare does https proxy
#  https:
#    address: ":443"
#    forwardedHeaders:
#      insecure: true

  traefik:
    address: ":8081"

# tls:
#   options:
#     default:
#       minVersion: VersionTLS12

log:
  level: INFO
  format: json

accessLog:
  format: json

api:
  dashboard: true
  insecure: true

# https://doc.traefik.io/traefik/v1.7/configuration/logs/
traefikLog:
  filePath: "/alloc/log/trafic.log"
  format: "json"
  statusCodes:
  - 200
  - 300-302

metrics:
  prometheus:
    entryPoint: "traefik"

providers:
  # enable file provider for certificates
  # file:
  #   filename: /certs/certificates.yaml
  #   watch: true

  # Enable Consul Catalog configuration backend.
  consulCatalog:
    refreshInterval: 30s
    prefix: "traefik"
    exposedByDefault: false
    endpoint:
      address: 127.0.0.1:8500
      scheme: http

EOF

        destination = "local/traefik.yaml"
      }

      resources {
        cpu    = 100
        memory = 64

        network {
          mbits = 100

          port "http" {
            static = 80
          }

	        # port "https" {
          #   static = 443
          # }

          port "api" {
            static = 8081
          }
        }
      }

      service {
        name = "traefik"
        tags = ["metrics"]
        port = "api"

        check {
          name     = "alive"
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "5s"
        }
      }
    }
  }
}
