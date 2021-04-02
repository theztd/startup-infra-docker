variable "dcs" {
    type   = list(string)
    default = ["dev", "dc1"]
}

variable "fqdn" {
    type    = string
}

job "grafana" {
  datacenters = var.dcs
  type        = "service"
  namespace   = "system"

  group "grafana" {
    count = 1
    
    network {
      port "grafana_http" { to = "3000"}
    }

    ephemeral_disk {
      size      = 300
      sticky    = true
      migrate   = true
    }

    service {
      name = "graphana"
      port = "grafana_http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.prometheus-http.rule=Host(`${var.fqdn}`)",
      ]

      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana"
        ports = ["grafana_http"]
      }

      resources {
        cpu    = 100
        memory = 32
      }

    }
  }
}
