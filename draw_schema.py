from diagrams import Cluster, Diagram, Edge
from diagrams.onprem.compute import Server, Nomad
from diagrams.onprem.network import Consul, Traefik, Nginx
from diagrams.onprem.container import Docker
from diagrams.onprem.monitoring import Grafana, Prometheus
from diagrams.onprem.iac import Ansible
from diagrams.saas.cdn import Cloudflare
# from diagrams.onprem.logging import Loki
# from diagrams.onprem.security import Vault
# from diagrams.onprem.vcs import Gitlab
# from diagrams.programming.language import Go
# from diagrams.programming.language import Python
# from diagrams.generic.os import LinuxGeneral
# from diagrams.saas.chat import Slack

graph_attr = {
    "fontsize": "26",
    "bgcolor": "white"
}

with Diagram(name="\n\n\nInfrastructure as a Code for small startups", 
            show=True, graph_attr=graph_attr, outformat="png",
            filename="infra_scheme", direction="TB"):

    ansible = Ansible("IaaC")
    dns = Cloudflare("Cloudflare DNS and PROXY")

    grafana = Grafana("Visualize your metrics")
    nomad = Nomad("Nomad")
    nomad - grafana

    nomad - ansible

    with Cluster("production"):
        with Cluster("node1"):
            traefik = Traefik("Traefik")
            with Cluster("default"):
                apps = [
                    Docker("app1"),
                    Docker("app2"),
                    Docker("app3")
                ]
            with Cluster("System"):
                prometheus = Prometheus("Metrics exporter")
                agent = Nomad("Agent")
                consul = Consul("Consul")

            dns - traefik - apps - agent - nomad
            prometheus - grafana
            agent - ansible
            

        with Cluster("node2"):
            traefik = Traefik("Traefik")
            with Cluster("default"):
                apps = [
                    Docker("app1"),
                    Docker("app2"),
                    Docker("app3")
                ]
            with Cluster("System"): 
                prometheus = Prometheus("Metrics exporter")
                agent = Nomad("Agent")
                consul = Consul("Consul")
                
            dns - traefik - apps - agent - nomad
            prometheus - grafana
            agent - ansible


        with Cluster("node3"):
            traefik = Traefik("Traefik")
            with Cluster("default"):
                apps = [
                    Docker("app1"),
                    Docker("app2"),
                    Docker("app3")
                ]
            with Cluster("System"): 
                prometheus = Prometheus("Metrics exporter")
                agent = Nomad("Agent")
                consul = Consul("Consul")
                
            dns - traefik - apps - agent - nomad
            prometheus - grafana
            agent - ansible
