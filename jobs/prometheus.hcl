job "prometheus" {
  datacenters = ["dc1"]
  type        = "service"
  namespace   = "system"

  group "monitoring" {
    count = 1

    network {
      port "prometheus_ui" {
        to = "9090"
      }

    }

    service {
      name = "prometheus"
      port = "prometheus_ui"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.prometheus-http.rule=Host(`prometheus.fejk.net`)",
      ]

      check {
        name     = "prometheus_ui port alive"
        type     = "http"
        path     = "/-/healthy"
        interval = "10s"
        timeout  = "2s"
      }
    }

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    ephemeral_disk {
      size = 300
    }

    task "prometheus" {
      template {
        change_mode = "noop"
        destination = "local/prometheus.yml"

        data = <<EOH
---
global:
  scrape_interval:     5s
  evaluation_interval: 5s

scrape_configs:
  - job_name: 'cadvisor'

    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['cadvisor-cadvisor']

    metrics_path: /metrics

  - job_name: 'nomad_metrics'

    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['nomad-client', 'nomad']

    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep

    scrape_interval: 5s
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']
EOH
      }

      driver = "docker"

      config {
        image = "prom/prometheus:latest"

        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
        ]

        ports = ["prometheus_ui"]

      }

    }
  }
}
