job "promtail" {
  datacenters = ["prod", "dc1"]

  namespace    = "system"
  type = "system"

  meta {
    source = "git path to the deploy job"
  }

  priority = 100

  group "promtail" {
    count = 1

    network {
      dns {
        servers = ["172.17.0.1", "8.8.8.8", "1.1.1.1"]
      }
    }

    task "promtail" {
      driver = "docker"

      config {
        image = "grafana/promtail:master"

        args = [
          "-config.file",
          "local/promtail.yaml",
          "-client.url=${LOKI_URL}",
        ]

        # mount nomad's alloc dirs
        volumes = [
          "/var/nomad/:/nomad/"
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
        memory     = 32  # MB
        memory_max = 64  #MB
      }


      kill_timeout = "10s"

    } # END task promtail


  } # END group FE

}
