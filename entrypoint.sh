#!/bin/bash
set -e

# Garantir que os diretórios existam no volume /data
echo "Iniciando preparação do volume /data..."
mkdir -p /data/instances /data/store /data/logs /data/backups
chown -R node:node /data
echo "Volume preparado com sucesso."

# Executar migrações se necessário
echo "Executando scripts de banco de dados..."
. ./Docker/scripts/deploy_database.sh

# Iniciar a aplicação
echo "Iniciando Evolution API..."
exec npm run start:prod
