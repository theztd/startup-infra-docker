variable "dcs" {
    type = list(string)
    default = ["dc1", "dev"]
}

variable "fqdn" {
    type = string
}

job "loki" {
  datacenters = var.dcs
  namespace = "system"
  type = "service"

  group "loki" {
    count = 1

    network {
      mode = "bridge"
      port "http" { to = 3100 }
    }

    service {
      name = "loki"
      port = "http"


      tags = [
        "traefik.enable=true",
        "traefik.http.routers.loki-http.rule=Host(`${var.fqdn}`)",

        "traefik.http.routers.prometheus-http.middlewares=auth",
        "traefik.http.middlewares.auth.basicauth.users=grafana:HTPASSWD_HASH,log-writer:HTPASSWD_HASH"
      ]
      
    }

    task "loki" {
      driver = "docker"

      config {
        image = "grafana/loki"
        ports = ["http"]
        args = [
          "-config.file=/etc/loki/local-config.yaml"
        ]
      }

      template {
        data = file("./loki_conf.yml")
        destination = "local/loki.yml"
        perms = "0644"
      }

      resources {
        cpu = 400
        memory = 64
        memory_max = 256
      }

      restart {
        attempts = 20
      }

    }
  }
}
