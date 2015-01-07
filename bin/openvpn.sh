[supervisord]
nodaemon=true

[program:rsyslogd]
command=/usr/sbin/rsyslogd -n
process_name=%(program_name)s
autostart=true
autorestart=true
user=root
directory=/
priority=912
stdout_logfile=/var/log/supervisor/%(program_name)s-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)s-stderr.log

[program:openvpn]
command=/usr/local/sbin/bin/openvpn.sh
autostart=true
autorestart=true