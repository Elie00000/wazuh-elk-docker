#!/bin/bash

sudo curl -o logstash/templates/wazuh.json https://packages.wazuh.com/integrations/elastic/4.x-8.x/dashboards/wz-es-4.x-8.x-template.json

docker-compose up -d
