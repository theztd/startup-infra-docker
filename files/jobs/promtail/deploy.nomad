job "promtail" {
  datacenters = ["prod", "dc1"]

  // namespace    = "system"
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
