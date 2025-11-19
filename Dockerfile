# Utilisation d'une image de base compatible avec Wazuh et Logstash (ex: Ubuntu 22.04)
FROM ubuntu:22.04

# Mise à jour des paquets et installation des dépendances
RUN apt-get update && \
    apt-get install -y curl gnupg2 wget apt-transport-https lsb-release && \
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add - && \
    echo "deb https://packages.wazuh.com/4.7/ $(lsb_release -cs) main" | tee -a /etc/apt/sources.list.d/wazuh.list && \
    apt-get update

# Installation de Wazuh-manager
RUN apt-get install -y wazuh-manager && \
    systemctl enable wazuh-manager && \
    service wazuh-manager start

# Installation de Logstash (version à adapter selon la dernière disponible)
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
    echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-8.x.list && \
    apt-get update && \
    apt-get install -y logstash && \
    systemctl enable logstash

# Installation du plugin Logstash pour Elasticsearch
RUN /usr/share/logstash/bin/logstash-plugin install logstash-output-elasticsearch

# Création des répertoires pour les certificats et templates
RUN mkdir -p /etc/logstash/wazuh-certs && \
    mkdir -p /etc/logstash/templates && \
    mkdir -p /etc/logstash/conf.d

# Téléchargement du template Wazuh pour Elasticsearch
RUN curl -o /etc/logstash/templates/wazuh.json https://packages.wazuh.com/integrations/elastic/4.x-8.x/dashboards/wz-es-4.x-8.x-template.json

# Copie des certificats (à remplacer par vos propres certificats)
COPY root-ca.pem /etc/logstash/wazuh-certs/root-ca.pem

# Configuration du pipeline Logstash pour Wazuh
COPY wazuh-logstash.conf /etc/logstash/conf.d/wazuh-logstash.conf

# Ajout de l'utilisateur logstash au groupe wazuh pour accéder aux logs
RUN usermod -a -G wazuh logstash

# Exposition des ports nécessaires
EXPOSE 1514 1515 514 55000 9200

# Variables d'environnement pour les identifiants (à remplir au runtime)
ENV ELASTICSEARCH_USERNAME="votre_identifiant"
ENV ELASTICSEARCH_PASSWORD="votre_mot_de_passe"
ENV ELASTICSEARCH_HOST="192.168.1.95"

# Commande pour démarrer Wazuh et Logstash
CMD service wazuh-manager start && \
    service logstash start && \
    tail -f /dev/null
