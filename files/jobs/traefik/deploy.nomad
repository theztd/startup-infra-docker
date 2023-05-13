# rolling release version with http to https redirect and tls v12 minimum
variable "dcs" {
    type = list(string)
    default = ["dc1"]
}

variable "image" {
	type    = string
	default = "traefik:v2.10"
}

locals {
  // The cleanest way I've found to define secrets :-(
  secrets = join(",", [
    "marek:$apr1$DS5KwjtQ$U0HqeBc461vIsSBuyerph/"
  ])
}

job "traefik" {
    datacenters  = var.dcs
    namespace    = "system"
    type         = "system"

    meta {
        template = "traefik"
        git = "github.com/theztd/startup-infra-docker"
        managed_by = "ansible"
        image = var.image
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
            port "https" { to = 443 }
        }

        service {
            provider = "nomad"
            name = "traefik-api"
            port = "api"

            tags = [
                "public",
                "traefik.enable=true",
                "traefik.http.routers.${NOMAD_JOB_NAME}-http.rule=Host(`traefik-api.fejk.net`)",
                "traefik.http.middlewares.${NOMAD_JOB_NAME}-auth.basicauth.users=${local.secrets}",
                "traefik.http.routers.${NOMAD_JOB_NAME}-http.middlewares=${NOMAD_JOB_NAME}-auth"
            ]
        }

        service {
            provider = "nomad"
            name = "traefik"
            port     = "http"

            tags = [
                "metrics",
                "lb",
            ]

            check {
                name     = "alive"
                type     = "tcp"
                interval = "15s"
                timeout  = "5s"
            }
        }

        task "traefik" {
            driver = "docker"

            config {
                image        = var.image
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
