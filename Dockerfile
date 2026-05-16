FROM evoapicloud/evolution-api:latest

USER root

# Concentra todas as pastas importantes no volume único em /data para suportar o Fly.io
RUN mkdir -p /data/instances /data/store /data/logs /data/backups && \
    rm -rf /evolution/instances /evolution/store /evolution/logs /evolution/backups && \
    ln -s /data/instances /evolution/instances && \
    ln -s /data/store /evolution/store && \
    ln -s /data/logs /evolution/logs && \
    ln -s /data/backups /evolution/backups && \
    chown -R node:node /data
    
# Remover as URLs de database hardcoded no .env para permitir o funcionamento dos fly secrets
RUN if [ -f .env ]; then sed -i '/^DATABASE_CONNECTION_URI/d' .env && sed -i '/^DATABASE_URL/d' .env; fi

ENV TZ=America/Belem
ENV SERVER_PORT=8080
ENV DATABASE_PROVIDER=postgresql

EXPOSE 8080


# Nota: As variáveis de ambiente da Evolution API, como DATABASE_CONNECTION_URI,
# AUTHENTICATION_API_KEY, entre outras, devem ser definidas via fly secrets ou docker-compose.
