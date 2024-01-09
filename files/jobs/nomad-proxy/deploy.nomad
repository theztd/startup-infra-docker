variable "fqdn" {
    type = string
}

job "nomad-proxy" {
  region = "global"

  namespace = "default"

  type = "service"

  meta {
    template = "nomad-proxy"
    git = "github.com/theztd/startup-infra-docker"
    fqdn = var.fqdn
  }

  group "nginx" {

    network {

      port "nomad-ui" {
        to = 80
      }
    }

    service {
      name = "nomad-proxy"
      port = "nomad-ui"
      provider = "nomad"

      tags = [
            "http=true",
            "http.fqdn=${var.fqdn}"
      ]

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
        extra_hosts = [
          "nomad-master:${NOMAD_IP_nomad_ui}"
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
