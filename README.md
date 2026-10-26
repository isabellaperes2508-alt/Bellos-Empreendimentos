# Bellos Empreendimentos

Site público no Netlify, com acesso privado e dados no Supabase.

- Apresentação: https://bellos-empreendimentos.netlify.app/
- Floratta: https://bellos-empreendimentos.netlify.app/assets/portal/?empreendimento=floratta
- Administração geral: https://bellos-empreendimentos.netlify.app/assets/portal/?administracao=1

O endereço antigo no GitHub Pages (`isabellaperes2508-alt.github.io/Bellos-Empreendimentos/`) continua aceito pela função até o repositório virar privado. Depois disso só o Netlify publica, e a função pode deixar de listar a origem do GitHub em `ORIGINS`.

A conta geral de Isabella Cleto é ativada por um link privado, de uso único e com validade. O link não está neste repositório. Após a ativação, a administradora cadastra gestores por empreendimento. Gestores podem cadastrar corretores e proprietários; corretores gerenciam somente os proprietários que cadastraram. Nomes repetidos recebem um número ao final do usuário. As senhas temporárias devem ser trocadas no primeiro acesso.

## Estrutura em produção

`index.html` e `assets/landing.*`: apresentação pública.
`assets/portal/`: interface, login, perfis e instalação por empreendimento.
`supabase/functions/bellos-empreendimentos/`: API com autorização por perfil e empreendimento.
`supabase/schema.sql`: tabelas `bellos_emp_*`, funções de autenticação e contas.

A função Edge realiza autenticação própria de usuário/senha numérica de seis dígitos, sem alterar o Supabase Auth dos outros aplicativos no projeto compartilhado. `verify_jwt=false` é intencional: a API verifica o token opaco de sessão em cada chamada privada. A chave `SUPABASE_SERVICE_ROLE_KEY` fica exclusivamente no ambiente da função, nunca no navegador.

Senhas têm hash bcrypt; tokens são aleatórios, com apenas o hash persistido no banco. Sessões ficam somente na memória do navegador e expiram após 30 minutos sem atividade ou 12 horas totais. Reabrir o aplicativo exige login. Há limite de tentativas por conta e endereço de origem. Trocar ou redefinir senha e desabilitar usuário invalida sessões.

Todas as tabelas novas têm RLS, sem permissões de leitura/escrita para `anon` ou `authenticated`. O aviso informativo de RLS sem políticas é esperado: todo acesso passa pela função Edge com autorização explícita. Não habilitar políticas públicas nessas tabelas. Referência: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy

O `netlify.toml` e o workflow do GitHub Pages publicam os mesmos arquivos: `index.html` e `assets/`. A pasta `app/` contém a implementação Node anterior, preservada como referência, e não é utilizada pelo site atual. Não é necessário contratar hospedagem Node para esta versão.

## Dados e limites atuais

O inventário de Floratta preserva os 112 lotes e o mapa existentes. Os preços iniciais ainda são estimativas de demonstração, a conferir antes do uso comercial. Não foram migrados clientes fictícios ou acessos de demonstração. Pix e boleto reais não estão integrados; documentos registram referências, sem upload de arquivos. Instalação PWA depende do suporte do navegador e não oferece consulta offline de dados privados.

## Verificação

- Testes transacionais no Supabase: ativação, login, troca obrigatória de senha, invalidação de sessões, criação de contas, impedimento de elevar privilégios e limite de tentativas.
- `node tests/domain.mjs`: filtros de dados e ações por perfil.
- `node --test tests/interface.test.mjs`: entrada pública e navegação dos perfis com API simulada, executado com sucesso.
- `node tests/browser.cjs`: teste de navegador preparado, mas não executado neste ambiente por indisponibilidade do Chromium; requer Playwright e navegador Chromium. Defina `CODEX_PRIMARY_RUNTIME_NODE_MODULES` para a pasta que contém Playwright.

Para alterar o backend, aplicar migrações revisadas e publicar a função `bellos-empreendimentos`. Alterar arquivos no GitHub não publica automaticamente a função Supabase. Nunca publicar dados pessoais, senhas, tokens de ativação ou chaves secretas no repositório.
