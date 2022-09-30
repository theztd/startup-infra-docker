# Monitoring (Prometheus + Grafana)

[Prometheus](https://prometheus.io/docs/introduction/overview/)
- je time series databaze s zakladnim UI a toolingem pro stavbu monitoringu
- lze ho relativne snadno skalovat a tak je vhodne mit pro infrastrukturu nekolik prometheus serveru (napriklad pro kazdou cast infrastruktury, nebo pro ruzne ENV)


[Grafana](https://grafana.com/docs/)
- je univerzalni platforma na praci s grafy
- umi vizualizovat a korelovat data z ruznych zdroju (influxdb, prometheus, elasticsearch, loki, atp...)

## Rycle odkazy
 * [Grafana](https://graph) 
 * [Prometheus](http://prometheus) (zabespeceno base auth)


## Jak se dostavaji metriky do grafany

Kazdy server v infrastrukture je sledovan prometheem skrze [node_exportera](https://github.com/prometheus/node_exporter). Diky tomu je server prez konkretni porty schopen poskytnout prometheoci aktualni metriky. Konkretne node_exporter posloucha na portu **9100**. 

Nase nastaveni node_exportera nam umoznuje pridavat libovolne nove metriky pouhym vkladanim souboru ve vhodnem formatu do cesty **/var/metrics/JMENO_METRIKY.prom**. Vice v casti o [vlastnich metrikach](#vlastni-metriky).



## Notifikace

Monitoring pracuje se 4 zakladnimi stavy:

 * **OK** neni co resit
 * **Warning** udalost o ktere je vhodne vedet, ale nevyzaduje rychlou reakci
 * **Critical** urgentni problem, ktery opravdu stoji za okamzite reseni
 * **Unknown** neznamy stav, protoze jsme neobdrzeli zadna data (dle zdroje chyby muze byt critical, warning, ale i OK)


Existuji dva zpusoby jak vytvaret alerty:

### Prometheus alertmanager
Velmi detailne konfigurovatelne, ale trochu slozitejsi. K popisovani alertu je pouzivan promQL jazyk, ktery neni uplne intuitivni, ale existuje velka [databaze prikladu](https://awesome-prometheus-alerts.grep.to/rules.html) 

### Grafana alerts 
Mnohem jednodusi na konfiguraci, ale zaroven i o dost omezenejsi. Alerty jde delat jen z nekterych typu grafu a presto, ze i zde se na pozadi generuje dotaz v promQL, nejsou zde podporovane slozitejsi podminky.


### Notifikacni kanaly
Samozrejmosi je pro oba nastroje **slack** a **email**, mimo tyto zpusoby lze posilat notifikace i pomoci webhooku, takze napriklad napojeni na opsgenie, nebo jine nastroje take neni velky problem. Pomoci rozsireni testujeme momentalne napojeni na teams, ktere neni uplne optimalni, ale zatim to funguje.


## Vlastni metriky
 

### Texfile exporter (SNADNE)
Node_exporter bezici na kazdem stroji a jak je uvedeno vyse, propaguje metriky uvedene v /tmp/metrics adresari. Toho lze vyuzit pro snadne pridani sve metriky do promethea a nasledne grafany/alertmanagera.

 

Napriklad se rozhodnete reportovat delku nejake ulohy bezici na pozadi (treba konverze obrazku). Pro tento ucel staci do vaseho scriptu pridat radek podobajici se nasledujicimu

 

```bash
#!/usr/bin/env python3

import sys

METRIC_OUTPUT_FILE="/tmp/metrics/jmeno-aplikace_metrika.prom"

try:  
    with open(METRIC_OUTPUT_FILE, "w") as fout:
        print('jmeno_metriky{label="jeho_hodnota", dalsi_label="jina_hodnota"} hodnota_metriky', file=fout)

except IOError as err:
    print(f'JMENO_APLIKACE - Nepovedlo se mi zapsat metriku do souboru {METRIC_OUTPUT_FILE}, ale pokracuju', file=sys.stderr)
    print(err, file=sys.stdout)

```
 

**jmeno_metriky** - melo by byt unikatni a vypovidajici, dobrym zvykem je, kdyz obsahuje primo jmeno metriky nazev zdroje, ale v nekterych pripadech je vhodnejsi, jmeno zdroje umistit az do labelu. Pdorobnejsi dokumentace je zde Metric and label naming | Prometheus 

**label** - slouzi k filtrovani metrik, je indexovan a muze nest velke mnozstvi upresnujicich informaci, pokud je spravne definovan a pouzit

**hodnota_metriky** - mela by to byt ciselna hodnota (int, bool)

 

### Vlastni HTTP endpoint (IDEALNI)
Pokud by se nekdo rozhodl misto texfile exporteru mit sve metriky primo v aplikaci, staci vytvorit routu (typicky to  byva /metrics, ale neni to pravidlo) vracejici na GET requesty vystup podobny tomu nize (genrovany pomoci flask aplikace a prometheusexportera z navodu jeste nize)

 

```bash
# HELP python_gc_objects_collected_total Objects collected during gc
# TYPE python_gc_objects_collected_total counter
python_gc_objects_collected_total{generation="0"} 1001.0
python_gc_objects_collected_total{generation="1"} 28.0
python_gc_objects_collected_total{generation="2"} 0.0
# HELP python_gc_objects_uncollectable_total Uncollectable object found during GC
# TYPE python_gc_objects_uncollectable_total counter
python_gc_objects_uncollectable_total{generation="0"} 0.0
python_gc_objects_uncollectable_total{generation="1"} 0.0
python_gc_objects_uncollectable_total{generation="2"} 0.0
# HELP python_gc_collections_total Number of times this generation was collected
# TYPE python_gc_collections_total counter
python_gc_collections_total{generation="0"} 91.0
python_gc_collections_total{generation="1"} 8.0
python_gc_collections_total{generation="2"} 0.0
# HELP python_info Python platform information
# TYPE python_info gauge
python_info{implementation="CPython",major="3",minor="9",patchlevel="1",version="3.9.1"} 1.0
# HELP flask_exporter_info Information about the Prometheus Flask exporter
# TYPE flask_exporter_info gauge
flask_exporter_info{version="0.18.1"} 1.0
# HELP flask_http_request_duration_seconds Flask HTTP request duration in seconds
# TYPE flask_http_request_duration_seconds histogram
flask_http_request_duration_seconds_bucket{le="0.005",method="GET",path="/api/1.json",status="200"} 0.0
flask_http_request_duration_seconds_bucket{le="0.005",method="GET",path="/api/3.json",status="200"} 0.0
flask_http_request_duration_seconds_bucket{le="5.0",method="GET",path="/api/5.json",status="200"} 3.0
# TYPE flask_http_request_duration_seconds_created gauge
flask_http_request_duration_seconds_created{method="GET",path="/api/1.json",status="200"} 1.626942287144087e+09
flask_http_request_duration_seconds_created{method="GET",path="/api/3.json",status="200"} 1.626942300849689e+09
flask_http_request_duration_seconds_created{method="GET",path="/api/5.json",status="200"} 1.6269423125495622e+09
# HELP flask_http_request_total Total number of HTTP requests
# TYPE flask_http_request_total counter
flask_http_request_total{method="GET",status="200"} 19.0
# TYPE flask_http_request_created gauge
flask_http_request_created{method="GET",status="200"} 1.626942287144299e+09
# HELP flask_http_request_exceptions_total Total number of HTTP requests which resulted in an exception
# TYPE flask_http_request_exceptions_total counter
# HELP app_info Testing flask app
# TYPE app_info gauge
app_info{version="0.2"} 1.0
```


Na internetul lze najit mnzostvi tutorialu jak zpristupnit prometheus metriky ve flask aplikaci, vystup vyse je velmi podobny tomu z aplikace v tutorialu…

 

Takovy to endpoint je pal snadne pridat do promethea…
