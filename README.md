# Evolution API no Fly.io

Este projeto contém a configuração pronta (`Dockerfile` e `fly.toml`) para fazer o deploy da **Evolution API** no [Fly.io](https://fly.io/), utilizando volumes persistentes e garantindo a compatibilidade de permissões e boas práticas de segurança.

---

## 📋 Pré-requisitos

1. **Conta e CLI do Fly.io:**
   - Crie uma conta no [Fly.io](https://fly.io/).
   - Instale o CLI do Fly (`flyctl`) na sua máquina. ([Instruções de instalação](https://fly.io/docs/hands-on/install-flyctl/)).
   - Faça login rodando o comando:
     ```bash
     fly auth login
     ```

2. **Banco de Dados PostgreSQL:**
   - Recomendamos provisionar um banco PostgreSQL diretamente no Fly.io para aproveitar a rede interna de baixa latência:
     ```bash
     fly postgres create --name evolution-db-thalyson
     fly postgres attach evolution-db-thalyson --app evolution-api-thalyson
     ```

---

## 🚀 Passo a Passo para o Deploy

### Passo 1: Ajustar o Nome do Aplicativo
No arquivo `fly.toml`, a primeira linha define o nome da sua aplicação (ex: `app = 'evolution-api-thalyson'`).
Se você quiser usar outro nome (pois os nomes no Fly precisam ser únicos globalmente), altere-o no arquivo. Também ajuste a variável `SERVER_URL` na seção `[env]` para refletir a nova URL.

### Passo 2: Criar o Aplicativo
No terminal, execute:
```bash
fly apps create evolution-api-thalyson
```

### Passo 3: Criar o Volume Persistente
O Fly.io exige que você crie o volume de armazenamento antes de ligar a máquina. O `fly.toml` está configurado para procurar um volume chamado `evolution_data`.

Crie o volume na mesma região definida no `fly.toml` (neste caso, `gru` - São Paulo):
```bash
fly volumes create evolution_data --region gru --size 2
```

### Passo 4: Configurar as Variáveis Secretas (Secrets)
Para manter sua API segura e conectada corretamente, você deve configurar as seguintes variáveis:

> [!IMPORTANT]
> É necessário adicionar `?sslmode=disable` no final da URL de conexão caso esteja usando o PostgreSQL interno do Fly.io, pois a comunicação interna via Wireguard não utiliza TLS.

```bash
fly secrets set AUTHENTICATION_API_KEY="SUA_CHAVE_AQUI"
fly secrets set DATABASE_URL="postgresql://user:pass@host:5432/banco?schema=public&sslmode=disable"
fly secrets set DATABASE_CONNECTION_URI="postgresql://user:pass@host:5432/banco?schema=public&sslmode=disable"
```

### Passo 5: Fazer o Deploy
O comando abaixo enviará o `Dockerfile`, o `entrypoint.sh` e o `fly.toml` para o Fly.io para construir sua imagem:
```bash
fly deploy --ha=false
```
> [!TIP]
> O parâmetro `--ha=false` evita que o Fly tente criar duas máquinas simultaneamente, o que poderia causar erro de travamento no volume.

---

### 📱 Dica: Estabilidade do QR Code
Caso tenha problemas para ler o QR Code ou ele não apareça:
1. Verifique nos logs se a versão do WhatsApp Web emulada é compatível.
2. Você pode ajustar essa versão no `fly.toml` através da variável `CONFIG_SESSION_PHONE_VERSION`.
3. Se o erro persistir, apague a instância no Manager e crie uma nova para limpar resquícios de sessões anteriores no volume.

### Passo 6: Ajustar o Número de Máquinas (Scale)
Como volumes do Fly não podem ser compartilhados entre máquinas, force a execução de apenas uma máquina:
```bash
fly scale count 1 -y
```

---

## 🛠 Entendendo a Arquitetura e Soluções Aplicadas

1. **Volume Centralizado e QR Code (`entrypoint.sh`):**
   A Evolution API espalha dados por várias pastas. No Fly.io, volumes montados (como o `/data`) substituem o conteúdo da imagem. Para evitar o erro `ENOTDIR` (onde a API não consegue criar pastas em alvos de links simbólicos inexistentes), usamos o `entrypoint.sh` para:
   - Criar a estrutura de pastas (`instances`, `store`, `logs`, `backups`) dentro do volume no momento do boot.
   - Garantir as permissões de escrita para o processo da API.
   - Isso permite que o QR Code seja gerado e as sessões sejam salvas permanentemente.

2. **Correção de Conflito de `.env`:**
   A imagem original possui um `.env` hardcoded. Nosso `Dockerfile` limpa essas definições durante o build, forçando a API a usar exclusivamente os valores definidos via **Fly Secrets**.

3. **Migrações e Permissões:**
   O container inicia como `root` para permitir que o script de entrada prepare o volume e que o Prisma execute as migrações de banco de dados (`db:deploy`) com sucesso antes da aplicação subir.

---

## 🔍 Logs e Monitoramento

Verifique os logs em tempo real:
```bash
fly logs
```

Acesse o painel web:
```bash
fly dashboard
```
