#!/bin/bash

# Atualizar o sistema e instalar dependências
sudo yum update -y
sudo yum install -y git curl wget unzip postgresql

# Instalar Docker
sudo amazon-linux-extras install docker -y
sudo systemctl enable docker
sudo systemctl start docker

# Adicionar o usuário ec2-user ao grupo docker
sudo usermod -a -G docker ec2-user
sudo usermod -a -G docker ssm-user
newgrp docker

# Instalar Docker Compose
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verificar versões do Docker e Docker Compose
docker --version
docker-compose --version

# Instalar Node.js 18.x para n8n
curl -sL https://rpm.nodesource.com/setup_18.x | sudo -E bash -
sudo yum install -y nodejs

# Definir variáveis do RDS PostgreSQL
RDS_HOST="seu-endereco-rds.amazonaws.com"
RDS_DB="n8n"
RDS_USER="n8nuser"
RDS_PASSWORD="n8npassword"

# Criar um arquivo de configuração do PostgreSQL para se conectar ao RDS
echo "host=${RDS_HOST} dbname=${RDS_DB} user=${RDS_USER} password=${RDS_PASSWORD}" > /home/ec2-user/.pgpass
chmod 600 /home/ec2-user/.pgpass

# Verificar a conexão com o RDS PostgreSQL
psql -h ${RDS_HOST} -U ${RDS_USER} -d ${RDS_DB} -c "SELECT 1;"

# Clonar e configurar a Evolution API
git clone https://github.com/evolutionapi/evolution-api.git /home/ec2-user/evolution-api
cd /home/ec2-user/evolution-api
docker-compose up -d

# Configurar e rodar n8n com Docker
mkdir -p /home/ec2-user/n8n
cd /home/ec2-user/n8n

# Criar o arquivo Docker Compose para o n8n
cat <<EOF > docker-compose.yml
version: "3"
services:
  n8n:
    image: n8nio/n8n
    container_name: n8n
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
    volumes:
      - ~/.n8n:/root/.n8n
    restart: always
EOF

# Subir o n8n com Docker Compose
docker-compose up -d

# Finalizar
echo "Docker, Evolution API, n8n configurados com sucesso!"
echo "Conexão com RDS PostgreSQL estabelecida."
echo "Você pode acessar o n8n na URL: http://<IP_da_Instancia>:5678"
