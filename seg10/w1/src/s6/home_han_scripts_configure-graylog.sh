#!/bin/bash

echo '*.* @10.0.42.4:5140;RSYSLOG_SyslogProtocol23Format' > /etc/rsyslog.d/90-graylog.conf
systemctl restart rsyslog.service
