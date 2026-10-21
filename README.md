# Bellos Empreendimentos

Plataforma idealizada por **Isabella Cleto / Bellos Cliks**.

## Site público atual

O GitHub Pages publica `index.html` e `assets/` pelo fluxo `.github/workflows/pages.yml` já existente. A página mostra a apresentação da Bellos, sua criadora e os empreendimentos. A antiga entrada direta no painel administrativo foi substituída por esta apresentação.

O GitHub Pages é uma hospedagem estática. **Os logins e painéis privados ainda dependem da publicação da aplicação com servidor.** Até essa conexão, os botões explicam que o acesso está em configuração e não coletam senhas.

## Aplicação completa

A pasta [`app/`](app/) contém o servidor Node.js 24, o banco SQLite, a interface, as permissões e os aplicativos instaláveis por empreendimento. Veja [`app/LEIA-ME.md`](app/LEIA-ME.md) para configuração e publicação.

- Administração geral: apenas a criadora da plataforma.
- Gestor: administra seu empreendimento e os respectivos acessos.
- Corretor: vê seus atendimentos e cadastra/gerencia seus próprios proprietários.
- Proprietário: vê suas unidades, pagamentos e documentos vinculados, comunicados e solicitações.
- Usuário `nome.sobrenome`; senha de seis números; troca obrigatória da senha inicial; limites de tentativas e permissões verificadas no servidor.
- Manifesto instalável individual em `/e/<empreendimento>/manifest.webmanifest` e entrada direta no login do empreendimento.

Não há senha administrativa padrão. Crie sua conta exclusiva pelo comando `node scripts/create-admin.mjs`, dentro de `app/`, na hospedagem do servidor e usando o mesmo disco persistente.

## Conectar o site ao login

1. Publique a pasta `app` em hospedagem com Node.js 24, disco persistente e HTTPS, seguindo seu LEIA-ME.
2. Configure sua conta de administradora geral e cadastre os gestores, corretores e proprietários.
3. Em [`assets/site-config.json`](assets/site-config.json), preencha `appOrigin` com o endereço HTTPS da aplicação, por exemplo `https://app.seu-dominio.com.br` (somente origem, sem caminhos).
4. Faça o commit. O fluxo existente do Pages publica automaticamente a configuração. Os botões passarão a levar ao login correto; a lista pública de empreendimentos será sincronizada pela API pública da aplicação quando disponível.

A chave `properties` desse arquivo é a lista pública de apoio, usada enquanto não houver servidor conectado ou durante indisponibilidade da consulta pública. Nunca inclua senhas, cadastros pessoais ou dados financeiros nesse arquivo.

## Testes

```sh
cd app
node --test test/*.test.mjs
```

Testes de API e interface simulada cobrem autenticação, troca de senha, limites de tentativas, revogação, isolamento entre empreendimentos e perfis e manifestos de instalação. A instalação física deve ser conferida no domínio HTTPS do servidor.

## Dados e versões anteriores

Os dados registrados nos HTMLs antigos eram locais ao navegador. Não são automaticamente migrados para este servidor. Faça backup antes de substituir cadastros. O mapa, a identidade e os materiais do Floratta foram mantidos; valores e áreas continuam sujeitos a validação. Pix/boleto permanecem demonstrativos e os documentos registram referências de arquivos.

O arquivo `bellos-empreendimentos.zip` que já estava no repositório é um pacote antigo, mantido como histórico. A versão atual com autenticação está em `app/`; esse ZIP não é publicado pelo fluxo do Pages.

Não versione pastas `data`, bancos SQLite, senhas ou arquivos `.env`. A aplicação inicializa sem contas prontas e guarda as senhas somente como hash com salt.
