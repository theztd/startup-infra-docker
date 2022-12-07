---
tags:
- grafana
- loki
---
# Logs (Promtail + Loki + Grafana)

## Promtail

Promtail is simple log parser reading log files and pushing them to loki. In this case promtail is nomad job.


### Start

Promtail job example is in files/jobs/promtail path. This example using nomad's variables storrage for storing LOKI_URL. So at first you have to set this variable in nomad.


### Configure nomad variable

```bash
nomad var put @my_secrets.hcl
```

where **my_secrets.hcl** is file containing this
```hcl
namespace = "system"
path = "nomad/jobs/promtail"

items {
    loki_url = "Secret url to loki with auth"
}
```

### Deploy promtail job

Simple go to the path where the promtail job with promtail.yaml sit and run nomad run command

```bash
nomad run promtail.nomad

```


## Loki

For very small i frastructures I recommend to use free grafana cloud, where is enough ressources for sending hundreds lines of log and keep short history. For those, who already have nodes for infrastructure workloads like monitoring, there is example loki configuration in path **files/jobs/loki**

### Important !!!

Your nomad cluster have to have working consul connect.


## Grafana

In grafana simple add **loki** data source and start with exploring your logs via grafana explorer