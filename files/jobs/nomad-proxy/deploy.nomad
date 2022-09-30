variable "dcs" {
    type = list(string)
    default = ["dc1", "dev"]
}

variable "fqdn" {
    type = string
}

job "nomad-proxy" {
  region = "global"

  datacenters = var.dcs
  namespace = "system"

  type = "service"

  group "nginx" {

    network {

      port "nomad-ui" {
        to = 80
      }
    }

    service {
      port = "nomad-ui"

      tags = [
            "public",
            "traefik.enable=true",
            "traefik.http.routers.${NOMAD_JOB_NAME}-http.rule=Host(`${var.fqdn}`)"
      ]
#            I use cloudflare for https      
#            "traefik.http.routers.${NOMAD_JOB_NAME}-http.tls=true"
#      ]

      check {
        type = "http"
        path = "/"
        interval = "10s"
        timeout = "2s"
      }
    }


    task "nginx" {
      driver = "docker"

      config {
        image = "nginx"
        ports = ["nomad-ui"]
        volumes = [
          "local/nginx.conf:/etc/nginx/nginx.conf"
        ]
      }

      template {
        data = file("./nomad-proxy_nginx.conf")
        destination = "local/nginx.conf"
        perms = "0644"
      }

      resources {
        cpu = 50
        memory = 16
      }

    }

  }
}
