variable "fqdn" {
  type = string
}

variable "dcs" {
  type    = list(string)
  default = ["dc1"]
}

variable "image" {
	type    = string
	default = "prom/prometheus:v2.43.0"
}

locals {
  // The cleanest way I've found to define secrets :-(
  secrets = join(",", [
    "marek:$apr1$DS5KwjtQ$U0HqeBc461vIsSBuyerph/"
  ])
}


job "monitoring" {
  datacenters   = var.dcs
  type          = "service"
  namespace     = "default"

  meta {
		fqdn = var.fqdn
    git = "github.com/theztd/startup-infra-docker"
    managed = "ansible"
    image = var.image
	}


  group "prometheus" {
    count = 1

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    network {
      port "http" {
        to = 9090
      }
    }

    service {
      name = "prometheus"
      port = "http"
      provider = "nomad"			

      tags = [
          "traefik.enable=true",
          "traefik.http.routers.${NOMAD_JOB_NAME}-http.rule=Host(`${var.fqdn}`)",
          "traefik.http.middlewares.${NOMAD_JOB_NAME}-auth.basicauth.users=${local.secrets}",
          "traefik.http.routers.${NOMAD_JOB_NAME}-http.middlewares=${NOMAD_JOB_NAME}-auth"
      ]

      check {
        name     = "prometheus_ui port alive"
        type     = "http"
        path     = "/-/healthy"
        interval = "10s"
        timeout  = "2s"
      }
    }

    ephemeral_disk {
      size      = 300
      sticky    = true
      migrate   = true
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = var.image
        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
        ]
        ports = ["http"]
      }

      resources {
        cpu    = 200 # MHz
        memory = 256 # MB
      }

      template {
        change_mode = "noop"
        destination = "local/prometheus.yml"
        data = file("prometheus.yml")
      }

      template {
        destination = "local/monitoring.sec"
        data = <<EOT
        # Generate ENV from all nomad vars
        {{ with nomadVar "nomad/jobs/monitoring" }}{{ .Parent.Items | sprig_toJson | parseJSON | toTOML }}{{end}}
        EOT
      }

      template {
        destination = "local/nomad_token.sec"
        data = <<EOT
{{ with nomadVar "nomad/jobs/monitoring" }}{{ .nomad_token }}{{ end }}
        EOT
      }

      template {
        destination = "local/node_exporter_password.sec"
        data = <<EOT
{{ with nomadVar "nomad/jobs/monitoring" }}{{ .node_exporter_password }}{{ end }}
        EOT
      }

    } # END task prometheus

  }
}
