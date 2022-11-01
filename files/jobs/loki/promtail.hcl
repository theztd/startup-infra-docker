/*
    Example using sidecar job.

    It is better because it goes around traefik and the log transfer is encrypted.

*/

job "promtail" {
  type        = "system"
  datacenters = ["dc1"]
  namespace   = "system"

  group "promtail" {
    network {
      mode = "bridge"

      // ports
      port "http" {
        to = 80
      }

    } // END Network
     
      service {
        name = "promtail"
        port = "http"
        tags = ["monitoring","prometheus"]

        check {
          name     = "Promtail HTTP"
          type     = "http"
          path     = "/targets"
          interval = "5s"
          timeout  = "2s"

          check_restart {
            limit           = 2
            grace           = "60s"
            ignore_warnings = false
          }
        }
      } // END service promtail-http
    
    // services proxy
    service {
      name = "promtail"
      port = "80"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "loki"
              local_bind_port  = 3100
            }
          }
        }
      }
    }


    task "promtail" {
      driver = "docker"

      config {
        image = "grafana/promtail:master"

        args = [
          "-config.file",
          "local/promtail.yaml"
        ]

        # mount nomad's alloc dirs
        volumes = [
          "/var/nomad/:/nomad/",
          "/var/log/:/log/"
        ]
      }

      //templates
      template {
        destination = "local/config.yaml"
        data        = file("promtail.yaml")
      }

      resources {
        // resources
        cpu    = 50
        memory = 64
      }
    }
  }
}