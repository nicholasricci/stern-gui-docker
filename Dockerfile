# Fase 1: Build del progetto Angular
FROM node as builder

# Imposta la directory di lavoro nel container
WORKDIR /app

# Copia i file del progetto Angular
RUN wget -O stern-gui.zip https://github.com/nicholasricci/stern-gui/archive/refs/heads/main.zip && \
    unzip stern-gui.zip && \
    mv stern-gui-main/* . && \
    rm -fr stern-gui-main stern-gui.zip

# Installa Angular CLI
RUN npm install -g @angular/cli

# Installa le dipendenze del progetto e costruiscilo
RUN npm install && npm run build

# Fase 2: Configurare Apache e avviare il processo Python Flask
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

# Installa Apache, Python, pip e altri strumenti necessari
RUN apt-get update && \
    apt-get install -y apache2 apache2-utils && \
    apt-get install -y python3 python3-pip wget zip && \
    a2enmod proxy proxy_http proxy_balancer rewrite && \
    rm -rf /var/lib/apt/lists/*

# Copia la build del progetto Angular dalla fase di build
COPY --from=builder /app/dist/stern-gui/browser /var/www/html

# Configura il VirtualHost di Apache
RUN echo '\n\
<VirtualHost *:80>\n\
    DocumentRoot /var/www/html\n\
    RewriteEngine on\n\
    # per le api verso il backend\n\
    RewriteRule ^/api/(.*)$ http://127.0.0.1:5000/api/$1 [P]\n\
    <Location /socket.io>\n\
        ProxyPass        http://127.0.0.1:5000/socket.io\n\
        ProxyPassReverse http://127.0.0.1:5000/socket.io\n\
    </Location>\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Copia lo script e le dipendenze Python Flask nel container
WORKDIR /app

RUN wget -O stern-daemon.zip https://github.com/nicholasricci/stern-daemon/archive/refs/heads/main.zip && \
    unzip stern-daemon.zip && \
    mv stern-daemon-main/* . && \
    rm -fr stern-daemon-main stern-daemon.zip && \
    pip3 install -r requirements.txt

# Installazione di oc e kubectl
RUN wget -O oc.tar.gz https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-server-v3.11.0-0cbc58b-linux-64bit.tar.gz && \
    tar -xvf oc.tar.gz && \
    mv openshift-origin-server-v3.11.0-0cbc58b-linux-64bit/oc /usr/local/bin/oc && \
    mv openshift-origin-server-v3.11.0-0cbc58b-linux-64bit/kubectl /usr/local/bin/kubectl && \
    rm -fr oc.tar.gz openshift-origin-server-v3.11.0-0cbc58b-linux-64bit

RUN wget -O stern.tar.gz https://github.com/stern/stern/releases/download/v1.28.0/stern_1.28.0_linux_amd64.tar.gz && \
    tar -xvf stern.tar.gz && \
    mv stern /usr/local/bin/stern && \
    rm -fr stern.tar.gz

# Avvia Apache in background e l'app Flask
CMD service apache2 start && python3 run.py
