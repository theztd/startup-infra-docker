job "s3" {
  datacenters = ["dc1"]

  constraint {
    attribute = "${node.class}"
    value     = "node"
  }

  group "minio" {
    ephemeral_disk {
      migrate = true
      size    = "500"
      sticky  = true
    }

    task "minio" {
      driver = "docker"

      config {
        image = "minio/minio"

        volumes = [
          "local/export:/export",
        ]

        args = [
          "server",
          "/export",
        ]

        port_map {
          minio = 9000
        }
      }

      env {
        MINIO_ACCESS_KEY = ""
        MINIO_SECRET_KEY = ""
      }

      service {
        name = "minio"
        tags = [
            "s3",
            "traefik.enable=true",
            "traefik.frontend.rule=Host:s3.fejk.net"
        ]

        port = "minio"

        check {
          type     = "http"
          path     = "/minio/login"
          port     = "minio"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        network {
          mbits = 50

          port "minio" {
            static = 9000
          }
        }
      }
    }
  }
}
