variable "loki_url" {
  type = string
  default = "https://localhost:3100/loki/api/v1/push"
}

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
    


/*
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
*/

    task "promtail" {
      driver = "raw_exec"

      // artifacts
      artifact {
        source      = "https://github.com/grafana/loki/releases/download/v2.3.0/promtail-linux-amd64.zip"
        mode        = "file"
        destination = "local/promtail"
      }

      env {
        AGENT_NAME = "${attr.unique.hostname}"
      }

      //templates
      template {
        destination = "local/config.yaml"
        data        = <<EOF
positions:
  filename: /tmp/positions.yaml

client:
  url: ${var.loki_url}

scrape_configs:
- job_name: 'nomad-logs'
  consul_sd_configs:
    - server: '172.17.0.1:8500'
  relabel_configs:
    - source_labels: [__meta_consul_node]
      target_label: __host__
    - source_labels: [__meta_consul_service_metadata_external_source]
      target_label: source
      regex: (.*)
      replacement: '$1'
    - source_labels: [__meta_consul_service_id]
      regex: '_nomad-task-([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})-.*'
      target_label:  'task_id'
      replacement: '$1'
    - source_labels: [__meta_consul_tags]
      regex: ',(app|monitoring),'
      target_label:  'group'
      replacement:   '$1'
    - source_labels: [__meta_consul_service]
      target_label: job
    - source_labels: ['__meta_consul_node']
      regex:         '(.*)'
      target_label:  'instance'
      replacement:   '$1'
    - source_labels: [__meta_consul_service_id]
      regex: '_nomad-task-([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})-.*'
      target_label:  '__path__'
      replacement: '/var/nomad/alloc/$1/alloc/logs/*std*.{?,??}'
EOF

      }

      config {
        // config
        command = "local/promtail"
        args    = ["-config.file=local/config.yaml", "-config.expand-env=true", "-print-config-stderr"]
      }

      resources {
        // resources
        cpu    = 50
        memory = 64
      }
    }
  }
}