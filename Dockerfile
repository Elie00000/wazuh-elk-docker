FROM ubuntu:latest

# Installer les dépendances nécessaires
RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    apt-transport-https \
    lsb-release \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Ajouter le dépôt Wazuh et installer Wazuh Manager
RUN curl -s https://packages.wazuh.com/4.7/wazuh.key | apt-key add - \
    && echo "deb https://packages.wazuh.com/4.7/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list \
    && apt-get update \
    && apt-get install -y wazuh-manager

# Installer Logstash
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - \
    && echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list \
    && apt-get update \
    && apt-get install -y logstash

# Configurer Logstash pour fonctionner avec Wazuh Manager
COPY logstash/config/logstash.conf /etc/logstash/conf.d/logstash.conf

# Exposer les ports nécessaires
EXPOSE 1514/udp 1515 514/udp 55000 5000

# Démarrer Wazuh Manager et Logstash
CMD service wazuh-manager start && service logstash start && tail -f /dev/null
