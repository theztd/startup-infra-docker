job "nginx-ingress" {
  type = "system"

  update {
    max_parallel      = 2
    health_check      = "checks"
    min_healthy_time  = "5s"
    auto_revert       = true
  }

  group "server" {
    network {
      port "http" {
        static = 80

      }
      
      port "https" {
        static = 443

      }
      
      port "status" {
        static = 9999

      }
      
    }
    
    service {
			provider = "nomad"
      port = "http"
      check {
        type = "http"
      	name = "nginx-ingress-http"
        path = "/"
      
      	interval = "5s"
      	timeout  = "1s"
      }

      /*
      // nomad service discovery does not support scripts
      check {
        name      = "config-check"
        type      = "script"
        command   = "/usr/sbin/nginx"
        args      = ["-t"]
        interval  = "5m"
        timeout   = "10s"
      }
      */

    }
    
    task "nginx-ingress" {
      driver = "docker"

      config {
        image   = "nginx:alpine-slim"

        // neobchazi firewall
        network_mode = "host"
        
        ports = [
        	"http",
          "https",
          "status"
        ]
        
         volumes = [
        	 "alloc/data/:/etc/nginx/conf.d/",
           "local/nginx.conf:/etc/nginx/nginx.conf",
           "local/admins:/etc/nginx/admins",
      	]
      }

      template {
        destination = "local/nginx.conf"
        data        =<<EOF
user                        nginx;
worker_processes            auto;

error_log                   /var/log/nginx/error.log notice;
pid                         /var/run/nginx.pid;


events {
    worker_connections          1024;
}


http {
    include                     /etc/nginx/mime.types;
    default_type                application/octet-stream;

    sendfile                    on;
    tcp_nopush                  on;
    tcp_nodelay                 on;
    server_tokens               off;
    types_hash_max_size         2048;

    # Test
    client_max_body_size        0;
    client_body_buffer_size     8K;
    proxy_max_temp_file_size    0;

    keepalive_timeout           65;

    log_format main escape=json '{"time": $msec, '
        '"resp_body_size": $body_bytes_sent, '
        '"host": "$http_host", '
        '"address": "$remote_addr", '
        '"request_length": $request_length, '
        '"method": "$request_method", '
        '"uri": "$request_uri", '
        '"status": $status, '
        '"user_agent": "$http_user_agent", '
        '"resp_time": $request_time, '
        '"upstream_addr": "$upstream_addr", '
        '"upstream_status": "$upstream_status", '
        '"upstream_header_time": "$upstream_header_time", '
        '"upstream_response_time": "$upstream_response_time", '
        '"upstream_connect_time": "$upstream_connect_time", '
        '"freelo_ident": "$http_x_freelo_ident", '
        '"freelo_ident_sent": "$sent_http_x_freelo_ident", '
        '"referer": "$http_referer"}';

    access_log                  /dev/stdout main;

    # Want to stream data directly without caching
    proxy_buffering 						off;
    fastcgi_buffers             32 32k;
    fastcgi_buffer_size         64k;

    fastcgi_param HTTP_PROXY    "";

    proxy_connect_timeout       43200000;  # 500 dni
    proxy_read_timeout          43200000;  # 500 dni
    proxy_send_timeout          43200000;  # 500 dni

    gzip                        on;
    gzip_disable                "msie6";
    gzip_types                  text/css 
                                text/x-component
                                application/x-javascript
                                application/javascript
                                text/javascript
                                text/x-js
                                text/richtext
                                image/svg+xml
                                text/plain 
                                text/xsd 
                                text/xsl 
                                text/xml 
                                image/x-icon;

    add_header                  Strict-Transport-Security max-age=63072000;
    add_header                  X-XSS-Protection "1; mode=block";
    proxy_cookie_path           / "/; secure";
    add_header                  X-Content-Type-Options nosniff;
    
    # SSL security
    ssl_prefer_server_ciphers on;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-CCM:DHE-RSA-AES256-CCM8:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-CCM:DHE-RSA-AES128-CCM8:DHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256;
  
    # Performance (minimize TTFB)
    ssl_buffer_size 8k;
    ssl_session_tickets off;
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 5m;
    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
  
  
    server {
    	listen 										80 default_server;
#      listen										443 default_server ssl;
      
      server_name								_;
      
      root          /usr/share/nginx/html/;
#    	ssl_certificate /etc/nginx/certs/freelo_cz.crt;
#  		ssl_certificate_key /etc/nginx/certs/freelo_cz.key;
    }
    
    server {
    	listen										9999;
      
      location /_nginx {
					stub_status on;
      # Schovane jen za VPN
 			# 		allow 127.0.0.1;
  		# 		deny all;
    	}
    }

    include                     /etc/nginx/conf.d/*.conf;
}

EOF
        perms       = "0644"
      }


      // Prez nomad vars spravovany seznam baseauth tokenu
			template {
      	destination = "local/admins"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data        = <<EOF
# Managed by nomad variables
{{- if nomadVarExists "nomad/jobs/nginx-ingress" }}
{{- with nomadVar "nomad/jobs/nginx-ingress" }}
{{- range . -}}

{{- if ( .Key | contains "baseauth_admins") }}
{{ . }}
{{- end -}}

{{- end }}
{{- end }}
{{- end }}

EOF
				perms = "0644"
      }




      template {
        # /usr/sbin/nginx -s reload
        destination = "alloc/data/defaults.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data        = <<EOF
# Managed by nomad service discovery

{{- range nomadServices }}
	{{- if .Tags | contains "http=true" -}}
    {{- $hostname := "example.com" -}}
    {{- $route := "/" -}}
    {{- $port := "80" -}}
    {{- $portSSL := "443" -}}
    {{- $baseAuth := "" -}}
    {{- $allowIPS := "" -}}
    {{- $certName := "" -}}
     
    {{- range .Tags -}}
      {{- $kv := (. | split "=") -}}
      {{- if eq (index $kv 0) "http.url" -}}
        {{- $hostname = (index $kv  1) -}}
      {{- end -}}
     	{{- if eq (index $kv 0) "http.route" -}}
        {{- $route = (index $kv  1) -}}
      {{- end -}}
    	{{- if eq (index $kv 0) "http.port" -}}
        {{- $port = (index $kv  1) -}}
      {{- end -}}
      {{- if eq (index $kv 0) "http.baseAuth" -}}
        {{- $baseAuth = (index $kv  1) -}}
      {{- end -}}
      {{- if eq (index $kv 0) "http.allowIPS" -}}
        {{- $allowIPS = (index $kv  1) -}}
      {{- end -}}
      {{- if eq (index $kv 0) "http.portSSL" -}}
        {{- $portSSL = (index $kv  1) -}}
      {{- end -}}
      {{- if eq (index $kv 0) "http.certName" -}}
        {{- $certName = (index $kv  1) -}}
      {{- end -}}
		{{- end -}}

# {{ .Name }}
# {{ . }}
upstream {{ .Name | toLower }} {
{{- range nomadService .Name }}
  # {{ .ID }}
  server {{ .Address }}:{{ .Port }};
{{ end }}
}

server {
  listen {{$port}};
  {{- if $certName }}
  listen {{ $portSSL }} ssl;
  {{- end }}
  {{- if $hostname}}
  server_name {{$hostname}};
  {{- end}}
  http2 on;

  access_log    /dev/stdout main;

  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header Host $http_host;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Host $host;
  proxy_set_header X-Forwarded-Port $server_port;
  
  {{ if $certName }}
  # Defined http.certName
  ssl_certificate /etc/nginx/certs/{{ $certName }}.crt;
  ssl_certificate_key /etc/nginx/certs/{{ $certName }}.key;
  ssl_dhparam /etc/nginx/certs/dhparam.pem;
  {{- end }}

  location {{$route}} {
     proxy_pass http://{{ .Name | toLower }};
     
     satisfy any;
     {{ if $allowIPS }}
     # Defined http.allowIPS
     {{- $ips := $allowIPS | split "," }}
     {{- range $ips }}
     allow {{ . }};
     {{- end }}
     deny all;
     {{- end }}
     
     {{- if $baseAuth }}
     # Defined http.baseAuth
     auth_basic "Administrator’s Area";
     auth_basic_user_file "{{$baseAuth}}";
     {{ end }}
  }
}

# END {{ .Name }}

	{{- end -}}
{{- end -}}
EOF
      }
      

      resources {
        cpu    = 200
        memory = 64
      }
    }
  }
}
