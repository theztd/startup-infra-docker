# Consul


[Consul](https://consul.io) je aplikace distribuovana jako jedina binarka, ktera umi plnit mnoho funkci a roli, ale vsechny tyto funkce se toci kolem:

  - centralizovany registr sluzeb
  - rozlicne konfigurovatelne health checky (tcp, udp, http, https, L7, …)
  - KV uloziste
  - snadno pouzitelne API a DNS interface pro cteni dat
  - mTLS komunikace
  - snadny clustering a rychle sireni dat mezi uzly (diky gRPC protokolu)

### Dashboard

Prijemne prostredi urcene pro prehled nad spravovanymi daty (konfigurace probiha po API, CLI, atp)


### CLI

Aktivace autocomplete

```bash
consul -install-autocomplete
```

# Instalace / Pridani node

### Consul

Cela konfigurace probiha prez ansible, po pridani noveho serveru staci jen pridat server do ./env/${ENV}/hosts do sekce metrics-only a nasledne pustit playbook consul.yml, viz priklad nize

```bash
ansible-playbook -i env/prod/hosts consul.yml --limit "JMENO_NOVEHO_STROJE"
```

### Konfigurace DNS resolvingu

Jedine co je potreba nastavit je **/etc/resolv.conf** a to napriklad takto

```bash
# na prvnim miste musi byt localhost
nameserver 127.0.0.1
nameserver 1.1.1.1
nameserver 8.8.8.8
...
```

Nasledne se o resolving stara dnsmasq, ktery routuje pozadavky dle domeny do consula, nebo na nejaky s verejnych DNS serveru.


Pokud by se cokoli rozbilo, staci v **/etc/resolv.conf** odebrat nameserver 127.0.0.1 a dnsmasq i s consulem bude preskakovan



# Pouziti

Consul nam púoskytuje moznost hledat sluzby v infrastrukture pomoci API i DNS.

Prostrednictvim API jsou videt vzdy vsechny servisy v libovolnem stavu a je tedy nutne, kontrolovat jejich stav pred pouzitim ve vasem kodu. Pokud se doptavame na sluzbu prez DNS, je nam vracena vzdy jen dostupna sluzba, v pripade, ze je u ni definovan i health check.

### Hledani pomoci DNS

```bash
# zakladni dotaz, ktery mi vrati IP na ktere sluzbu najdu
dig @localhost JMENO_SLUZBY.service.internal

# pokud chci nejake doplnkove informace, lze se zeptat jeste takto
# vystup casto obsahuje napriklad port, na kterem sluzbu najdu atp.
dig @localhost JMENO_SLUZBY.service.internal SRV
```

Pokud mam nastaven v resolv.conf nameserver na localhost v prvnim miste, nemusim uvadet @localhost pri resolvu.


### Hledani pomoci API

curl http://localhost:8500/v1/catalog/service/JMENO_SLUZBY?pretty


**Priklad querry vcetne vystupu**

```bash
@~ $  curl http://localhost:8500/v1/catalog/service/consul-ui?pretty
[
    {
        "ID": "1481fe46-b91b-5229-eafd-91febe6a9e98",
        "Node": "node-1",
        "Address": "10.0.6.11",
        "Datacenter": "prod",
        "TaggedAddresses": {
            "lan": "10.0.6.11",
            "lan_ipv4": "10.0.6.11",
            "wan": "10.0.6.11",
            "wan_ipv4": "10.0.6.11"
        },
        "NodeMeta": {
            "consul-network-segment": ""
        },
        "ServiceKind": "",
        "ServiceID": "consul-ui",
        "ServiceName": "consul-ui",
        "ServiceTags": [
            "http",
            "ui",
            "consul"
        ],
        "ServiceAddress": "",
        "ServiceWeights": {
            "Passing": 1,
            "Warning": 1
        },
        "ServiceMeta": {},
        "ServicePort": 8500,
        "ServiceSocketPath": "",
        "ServiceEnableTagOverride": false,
        "ServiceProxy": {
            "Mode": "",
            "MeshGateway": {},
            "Expose": {}
        },
        "ServiceConnect": {},
        "CreateIndex": 133,
        "ModifyIndex": 214
    }
]
```
 

## Jak pridat sluzbu s health checkem


Vzorova definice servisy s dvema checky. Nize uvedenou definici ulozime jako **node-1-svcs.json**
```json
{
  "service": {
    "name": "api",
    "tags": [
      "prometheus",
      "metrics",
      "mysqld_exporter"
    ],
    "port": 80,
    "checks": [
      {
        "name": "Check http",
        "http": "http://localhost/",
	"header": {
	  "Host": ["node-1"]
	},
        "interval": "15s",
        "timeout": "5s",
	"failures_before_critical": 3
      },
      {
        "name":  "Graphql check",
	"args": [
	  "/usr/local/bin/curl_stats_graphql", 
	  "http://localhost/graphql",
	  "api",
	  "version"
        ],
	"interval": "30s",
	"timeout": "5s",
	"failures_before_critical": 3
      }
    ]
  }
}
```

V prikladu je nadefinovana graphql sluzba na serveru node-1. Tato sluzba je kazdych 30s kontrolovana jak pomoci skriptu, tak primym dotazem po http. Pokud by check 3x za sebou selhal, bude sluzba oznacena za nefunkcni a bude odebrana z DNS. Pokud bychom tedy pouzivali napriklad v nginxu jako backend adresu api.service.internal, nginx by po 90s vypadku, tuto sluzbu vyradil a neposilal na ni dalsi requesty.

Takto vytvorenou sluzbu nasledne mohu nasadit nasledujicimi zpusoby:

### Po API curlem

```bash
curl -X PUT — data-binary @node-1-svcs.json http://<consul-server-ip:8500>/v1/agent/service/register
```

### Pomoci cli nastroje

```bash
consul services register node-1-svcs.json
```

### Pridanim staticke konfigurace do adresare na consul serveru

```bash
cat > /etc/consul/conf.d/node-1-svcs.json
consul reload
```

## Jak pridat pouze health check

Postup je stejny jako pro servisu, jednoduchy priklad je opet nize

```json
{
  "check": {
    "id": "consul-ui",
    "name": "Check consul-ui health",
    "http": "http://localhost:8500/ui/",
    "method": "GET",
    "service_id": "consul-ui",
    "interval": "10s",
    "timeout": "2s"
  }
}
```


Pokud chci check navazat primo na konkretni sluzbu a ne cely node, pak je nutne parametr service_id jako je v prikladu vyse. Pokud bych tento parametr nepridal, check se navaze na cely server a negativni vysledek jednoho testu pak muze oznacit **cely node za nedostupny**, pokud to navazu na konkretni sluzbu, je oznacena jen sluzba samotna a to je to co vetsinou chceme.


!!! note "Tutorial"
    Zde prikladam odkaz na pekny [tutorial v oficialni dokumentaci](https://learn.hashicorp.com/tutorials/consul/service-registration-health-checks). Za prohlednuti, ale stoji jiste i dalsi tutorialy, ktere lze najit v menu.

# Zalohovani a restore consul databaze


Pokud je consul centrem pravdy a pridavame do nej sluzby skrz API, je zalohovani vic nez zadouci, v pripade, kdy slouzi jen pro sdileni informaci mezi sluzbami a registrace sluzeb tak probiha skrz soubory, nebo externi sluzby (nomad, kubernetes, ...), zalohovani neni nutne.


```bash
 # Create a snapshot:
consul snapshot save backup.snap

# Restore a snapshot:
consul snapshot restore backup.snap

# Inspect a snapshot:
consul snapshot inspect backup.snap
```


