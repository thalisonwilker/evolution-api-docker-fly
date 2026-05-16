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
Execute:
```bash
fly deploy
```

### Passo 6: Ajustar o Número de Máquinas (Scale)
Como volumes do Fly não podem ser compartilhados entre máquinas, force a execução de apenas uma máquina:
```bash
fly scale count 1 -y
```

---

## 🛠 Entendendo a Arquitetura

1. **Volume Centralizado (`/data`):**
   A Evolution API por padrão espalha seus arquivos. No `Dockerfile`, criamos pastas dentro de `/data` e fazemos links simbólicos (symlinks) para `/evolution/instances`, `/evolution/store`, etc. Isso garante que todos os dados persistentes fiquem protegidos em um único volume.

2. **Correção de Conflito de `.env`:**
   A imagem original da Evolution API contém um arquivo `.env` fixo que aponta para `postgres:5432`. O nosso `Dockerfile` limpa essas linhas automaticamente no build para que o Prisma respeite corretamente as variáveis injetadas via **Fly Secrets**.

3. **Permissões de Root:**
   As migrações do banco (Prisma) exigem permissões de escrita em diretórios específicos durante o boot. O container roda como `root` para garantir que a sincronização das tabelas ocorra sem erros de permissão.

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
