# rolling release version with http to https redirect and tls v12 minimum
variable "dcs" {
    type = list(string)
    default = ["dc1", "devel", "prod", "eu1"]
}

job "traefik" {
    datacenters  = var.dcs
    namespace    = "system"
    type         = "system"

    meta {
        template = "traefik"
        git = "github.com/theztd/startup-infra-docker"
        managed_by = "ansible"
    }
    
    # rolling release
    update {
        max_parallel      = 1
        health_check      = "checks"
        min_healthy_time  = "30s"
        healthy_deadline  = "2m"
        auto_revert       = true
    }

    group "traefik" {
        count = 1

        network {
            port "api" { static = 8081 }
            port "http" { static = 80 }
            # port "https" { to = 443 }
        }

        service {
            provider = "nomad"
            name = "traefik"
            tags = ["metrics", "lb"]

            check {
                name     = "alive"
                type     = "tcp"
                port     = "http"
                interval = "15s"
                timeout  = "5s"
            }
        }

        task "traefik" {
            driver = "docker"

            config {
                image        = "traefik:v2.8"
                network_mode = "host"

                volumes = [
                    "local/traefik.yaml:/etc/traefik/traefik.yaml"
                ]


            } # END config

            resources {
                cpu    = 100
                memory = 64
            }

            template {
                destination = "local/traefik.yaml"
                data        = file("./traefik.yaml")
                perms       = "0644"
            }
        } # END task traefik

    } # END group traefik

}
