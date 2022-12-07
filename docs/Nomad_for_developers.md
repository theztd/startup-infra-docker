---
tags:
- nomad
- developers
---

# Nomad for developers


Primarnim zdrojem informaci pro vyvojare by mela byt skvela dokumentace na webu nomadproject.io, pripadne jako intro muze poslouzit ma prezentace na gdrive.


## Job example definition

```hcl
variable "fqdn" {
	type = string
  default = ""
	description = "Primaary application domain (will be used as ID for persistent storage, never change it!!!)"
}

variable "dcs" {
  type = list(string)
  default = ["dc1", "dev"]
}

job "example" {
  datacenters = var.dcs
  namespace = "default"
  type = "service"

  group "frontend" {
    count = 1

    # Unable to reschedule job to another node
    # Because using docker volumes nomad is not able to migrate jobs on his own
    reschedule {
      attempts  = 0
      unlimited = false
    }

    # Try to make local/ and alloc/data persistent (great for logs)
    ephemeral_disk {
        migrate = true
        size    = 500     # MB
        sticky  = true
    }


    network {
      mode = "bridge"
      port "http" {
        to = 80
      }
    }

    service {
      name = "${JOB}-http"

    	tags = [
            "public",
            "traefik.enable=true",
            "traefik.http.routers.${NOMAD_JOB_NAME}-http.rule=Host(`${var.fqdn}`)",
            "traefik.http.routers.${NOMAD_JOB_NAME}-http.tls=true"
      ]

      port = "http"

      check {
        name     = "${NOMAD_JOB_NAME} - alive"
        type     = "http"
        port     = "http"
        path     = "/_alive.html"
        interval = "30s"
        timeout  = "5s"

        # Task should run in 25m
        check_restart {
            limit = 5
            grace = "25m"
            ignore_warnings = true
        }
      } # check http endpoint

    }



    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:1.18"

        /* 
          # Nice for debuging
          entrypoint = ["sleep", "300000"]
          interactive = true
        */

      }

      env {
        ENV = production
        FQDN = var.fqdn
      }

      // resource limitation (CPU is not hard by default)
      resources {
        cpu    = 200 # MHz
        memory = 32 # MB
        memory_max = 128 # MB
      }

      // after unpacking it makes directory public (it is in archiv)
      artifact {
        source      = https://releases.fejk.net/webX/latest.tgz
        destination = "local"
      }

      mount {
          type     = "bind"
          source   = "..${NOMAD_ALLOC_DIR}/local/public"
          target   = "/usr/share/nginx/html"
          readonly = true
      }
    } // END nginx definition

  } // END group frontend

}


```



## WebUI

Basic interface for working with an application. It is intuitive and usefull for basic debuging.



## CLI

```bash
# Plne a okamzite smazani deploje, neceka se na GC
nomad stop -purge JMENO_APLIKACE


```


## Curl

### Event stream

Poslouchani na event streamu, hodi se pro nejake sekundarni reagovani na eventy, napriklad lze pouzit pro zalohovani volume po smazani jobu a nasledne odstraneni...

```bash 
curl -s -v -N http://127.0.0.1:4646/v1/event/stream
```
