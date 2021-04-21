job "cadvisor" {
  region = "global"

  datacenters = ["dc1"]
  namespace = "system"

  type = "system"

  group "cadvisor" {

    network {

      dns {
        servers = ["172.17.0.1", "8.8.8.8", "8.8.4.4"]
      }

      port "cadvisor" {
        to = 8080
        static = 8080
      }
    }

    service {
      port = "cadvisor"
      check {
        type = "http"
        path = "/"
        interval = "10s"
        timeout = "2s"
      }
    }


    task "cadvisor" {

      driver = "docker"

      config {
        image = "google/cadvisor"
        ports = ["cadvisor"]

      }

      resources {
        cpu = 100
        memory = 32
      }

    }
  }
}
