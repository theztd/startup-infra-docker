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
      port "http" { to = 3100 }
    }

    service {
      name = "loki"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.loki-http.rule=Host(`${var.fqdn}`)"
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

      restart {
        attempts = 20
      }

    }
  }
}
