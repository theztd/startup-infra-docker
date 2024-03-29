variable "image" {
	type    = string
	default = "grafana/promtail:2.8.2"
}

job "promtail" {
  namespace    = "system"
  type = "system"

  meta {
    git = "github.com/theztd/startup-infra-docker"
    managed = "ansible"
    image = var.image
	}

  priority = 100

  group "promtail" {
    count = 1

    network {
      dns {
        servers = ["172.17.0.1", "8.8.8.8", "1.1.1.1"]
      }

      port "http" { to = 9080 }
    }

    task "promtail" {
      driver = "docker"

      config {
        image = var.image

        args = [
          "-config.file",
          "local/promtail.yaml",
          "-client.url=${LOKI_URL}",
          "-config.expand-env=true"
        ]

        ports = ["http"]

        # mount nomad's alloc dirs
        volumes = [
          "/var/nomad/:/nomad/",
          "/var/run/docker.sock:/var/run/docker.sock"
        ]
      }

      template {
        data        = file("./promtail.yaml")
        destination = "local/promtail.yaml"
        perms       = "0640"
      }

      template {
        data         = <<EOT
{{ if nomadVarExists "nomad/jobs/promtail" }}
  {{ with nomadVar "nomad/jobs/promtail" }}
    LOKI_URL="{{ .loki_url }}"
  {{ end }}
{{ else }}
    LOKI_URL="PLACE_THERE_YOUR_URL@logs-prod-us-central1.grafana.net/api/prom/push"
{{ end }}

EOT
          env         = true
          destination = "secrets/loki.env"
          perms       = "0600"
        }

      env {
        HOSTNAME = attr.unique.hostname
      }

      resources {
        cpu        = 300 # MHz
        memory     = 100  # MB
        memory_max = 150  #MB
      }


      kill_timeout = "10s"

    } # END task promtail


  } # END group FE

}
