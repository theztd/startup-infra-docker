# prometheus basic monitoring
# - base auth via traefik
# - autodiscovery services (traefik currently)
# - nomad metrics (jobs, nodes)

# This deployment requires CONSUL

variable "fqdn" {
  type = string
}

variable "dcs" {
  type    = list(string)
  default = ["dc1"]
}

job "monitoring" {
  datacenters   = var.dcs
  type          = "service"
  namespace     = "system"

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

      # ZKKpyEpr7wcWLAl4C7xun4PkgRu/+3shLdn7659cfDC8lxjA+b3icJnLr
      # U3tF8khrI6dW7hRMz89yruaJNbc4yPqDPiv - gitlab
      tags = [
          "traefik.enable=true",
          "traefik.http.routers.${NOMAD_JOB_NAME}-http.rule=Host(`${var.fqdn}`)",
          "traefik.http.routers.${NOMAD_JOB_NAME}-http.tls=true"
//          "traefik.http.routers.${NOMAD_JOB_NAME}-http.middlewares=${NOMAD_JOB_NAME}-auth",
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
        image = "prom/prometheus:latest"
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
        data = <<EOH
---
global:
  scrape_interval:     5s
  evaluation_interval: 5s

scrape_configs:
  - job_name: 'traefik'
    consul_sd_configs:
    - server: '172.17.0.1:8500'
#      token: 'TOKEN'
      services: ['traefik']

#    relabel_configs:
#    - source_labels: ['__meta_consul_service_port']
#      target_label:  '__meta_consul_service_port'
#      replacement:   '8081'

    metrics_path: /metrics

  - job_name: 'nomad_metrics'

    consul_sd_configs:
    - server: '172.17.0.1:8500'
#      token: 'TOKEN'
      services: ['nomad-clients', 'nomad-servers', 'nomad']

    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep

    scrape_interval: 5s
    scheme: http
    tls_config:
      insecure_skip_verify: true
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']

EOH
      }

    } # END task prometheus

  }
}
