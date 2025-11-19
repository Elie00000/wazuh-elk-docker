# Utilisation d'une image de base Ubuntu 24.04
FROM ubuntu:24.04

# Définition de l'utilisateur root pour les opérations d'installation
USER root

# Mise à jour des paquets et installation des dépendances
RUN apt-get update && \
    apt-get install -y curl gnupg wget apt-transport-https lsb-release && \
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && \
    chmod 644 /usr/share/keyrings/wazuh.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list && \
    apt-get update

# Installation de Wazuh-manager
RUN apt-get install -y wazuh-manager && \
    systemctl enable wazuh-manager

# Installation de Logstash (version 9.x)
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/9.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-9.x.list && \
    apt-get update && \
    apt-get install -y logstash && \
    systemctl enable logstash

# Installation du plugin Logstash pour Elasticsearch
RUN /usr/share/logstash/bin/logstash-plugin install logstash-output-elasticsearch

# Création des répertoires pour les certificats et templates
RUN mkdir -p /etc/logstash/wazuh-certs && \
    mkdir -p /etc/logstash/templates && \
    mkdir -p /etc/logstash/conf.d && \
    mkdir -p /etc/sysconfig

# Téléchargement du template Wazuh pour Elasticsearch
RUN curl -o /etc/logstash/templates/wazuh.json https://packages.wazuh.com/integrations/elastic/4.x-8.x/dashboards/wz-es-4.x-8.x-template.json

# Copie des certificats (à remplacer par vos propres certificats)
COPY root-ca.pem /etc/logstash/wazuh-certs/root-ca.pem
RUN chmod 644 /etc/logstash/wazuh-certs/root-ca.pem

# Configuration du mot de passe du keystore Logstash
RUN echo 'LOGSTASH_KEYSTORE_PASS="<MY_KEYSTORE_PASSWORD>"' > /etc/sysconfig/logstash && \
    chown root:root /etc/sysconfig/logstash && \
    chmod 600 /etc/sysconfig/logstash

# Création du keystore Logstash et ajout des identifiants Elasticsearch
RUN /usr/share/logstash/bin/logstash-keystore --path.settings /etc/logstash create && \
    /usr/share/logstash/bin/logstash-keystore --path.settings /etc/logstash add ELASTICSEARCH_USERNAME && \
    /usr/share/logstash/bin/logstash-keystore --path.settings /etc/logstash add ELASTICSEARCH_PASSWORD

# Copie de la configuration Logstash pour Wazuh
COPY wazuh-logstash.conf /etc/logstash/conf.d/wazuh-logstash.conf

# Ajout de l'utilisateur logstash au groupe wazuh pour accéder aux logs
RUN usermod -aG wazuh logstash

# Exposition des ports nécessaires
EXPOSE 1514 1515 514 55000 9200

# Variables d'environnement pour les identifiants (à remplir au runtime)
ENV ELASTICSEARCH_USERNAME="votre_identifiant"
ENV ELASTICSEARCH_PASSWORD="votre_mot_de_passe"

# Commande pour démarrer Wazuh et Logstash
CMD service wazuh-manager start && \
    service logstash start && \
    tail -f /dev/null
