#!/usr/bin/env python3

from diagrams import Cluster, Diagram, Edge
from diagrams.onprem.compute import Server, Nomad
from diagrams.onprem.network import Consul, Traefik, Nginx
from diagrams.onprem.container import Docker
from diagrams.onprem.monitoring import Grafana, Prometheus
from diagrams.onprem.iac import Ansible
from diagrams.saas.cdn import Cloudflare
from diagrams.onprem.logging import Loki
# from diagrams.onprem.security import Vault
from diagrams.onprem.vcs import Gitlab
from diagrams.programming.language import Go
# from diagrams.programming.language import Python
# from diagrams.generic.os import LinuxGeneral
from diagrams.saas.chat import Slack

graph_attr = {
    "fontsize": "32",
    "bgcolor": "white"
}

cluster_attr = {
    "fontsize": "24"
}

with Diagram(name="\n\n\nInfrastructure as a Code for a small startups", 
            show=True, graph_attr=graph_attr, outformat="png",
            filename="infra_scheme", direction="TB"):

    #ansible = Ansible("Ansible\n(IaaC tool)")
    dns = Cloudflare("Cloudflare\n(DNS and PROXY)")
    
    #nomad = Nomad("Nomad")

    with Cluster("MGMT stack", graph_attr=cluster_attr):
        nomad = Nomad("Nomad\nCluster API and UI")
        ansible = Ansible("Ansible\n(IaaC tool)")
        grafana = Grafana("Grafana\n(Visualize metrics)")
        gitlab = Gitlab("Gitlab\n(CI/CD)")
        slack = Slack("Slack\n(Alerting and Cooperation)")

    with Cluster("Monitoring stack", graph_attr=cluster_attr):
        monitoring = [
            Loki("Loki\n(logs DB)"),
            Prometheus("prometheus\n(metrics DB)")
        ]
        monitoring - grafana

    with Cluster("production", graph_attr=cluster_attr):
        with Cluster("node1", graph_attr=cluster_attr):
            traefik = Traefik("Traefik")
            with Cluster("NS: default"):
                apps = [
                    Docker("app1"),
                    Docker("app2"),
                    Docker("app3")
                ]
            with Cluster("NS: System"):
                agent = Nomad("Agent")
                consul = Consul("Consul")
            
            node_exporter = Go("Metrics and Logs\nexporter")

            dns - traefik - Edge(color="red") - apps - agent - Edge(color="green", label="GRPC mgmt") - nomad
            apps - Edge(color="blue", style="dashed") - node_exporter - Edge(color="blue", style="dashed") - monitoring
            agent - Edge(color="blue", style="dashed") - monitoring
            agent - Edge(color="grey", style="dotted") - ansible
            

        with Cluster("node2", graph_attr=cluster_attr):
            traefik = Traefik("Traefik")
            with Cluster("NS: default"):
                apps = [
                    Docker("app1"),
                    Docker("app2"),
                    Docker("app3")
                ]
            with Cluster("NS: System"):
                agent = Nomad("Agent")
                consul = Consul("Consul")
            
            node_exporter = Go("Metrics and Logs\nexporter")
                
            dns - traefik - Edge(color="red") - apps - agent - Edge(color="green", label="GRPC mgmt") - nomad
            apps - Edge(color="blue", style="dashed") - node_exporter - Edge(color="blue", style="dashed") - monitoring
            agent - Edge(color="blue", style="dashed") - monitoring
            agent - Edge(color="grey", style="dotted") - ansible


        with Cluster("node3", graph_attr=cluster_attr):
            traefik = Traefik("Traefik")
            with Cluster("NS: default"):
                apps = [
                    Docker("app1"),
                    Docker("app2"),
                    Docker("app3")
                ]
            with Cluster("NS: System"):
                agent = Nomad("Agent")
                consul = Consul("Consul")
            
            node_exporter = Go("Metrics and Logs\nexporter")
                
            dns - traefik - Edge(color="red") - apps - agent - Edge(color="green", label="GRPC mgmt") - nomad
            apps - Edge(color="blue", style="dashed") - node_exporter - Edge(color="blue", style="dashed") - monitoring
            agent - Edge(color="blue", style="dashed") - monitoring
            agent - Edge(color="grey", style="dotted") - ansible
