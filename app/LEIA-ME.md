# Bellos Empreendimentos — acesso privado e aplicativo

Esta atualização substitui a entrada administrativa aberta por uma apresentação pública, seleção do empreendimento e login individual. Inclui o servidor e o banco SQLite que verificam as permissões. Não usa Supabase nem exige assinatura desse serviço.

## O que mudou

- Página pública com apresentação da Bellos, autoria de Isabella Cleto / Bellos Cliks e lista de empreendimentos.
- Administração geral exclusiva: somente sua conta cria empreendimentos e acessa o conjunto inteiro.
- Gestor: administração e acessos somente no empreendimento ao qual foi vinculado.
- Corretor: unidades do empreendimento, seus atendimentos e propostas, e os proprietários cadastrados por ele. Pode cadastrar proprietários; não cria gestores, corretores nem empreendimentos.
- Proprietário: somente suas unidades, parcelas vinculadas, documentos disponibilizados, comunicados do condomínio e solicitações.
- Usuário gerado por primeiro nome e último sobrenome: `ana.silva`. Em caso de repetição no mesmo empreendimento: `ana.silva2`.
- Senha de exatamente seis números. Senhas armazenadas com hash e salt, nunca em texto simples. Cinco tentativas incorretas bloqueiam novas tentativas nessa conta por 15 minutos; há também limite por origem de conexão.
- Troca obrigatória da senha inicial. Redefinição e desativação de conta encerram as sessões existentes.
- Aplicativo instalável por empreendimento. O atalho do Floratta abre `/e/floratta/?login=1`, sem passar pela lista geral. Ao abrir/recarregar a plataforma, o login é solicitado novamente. Isso também encerra uma sessão anterior do mesmo navegador.

## Arquivos necessários

Publique **o projeto completo**, incluindo `server.mjs`, `storage.mjs`, `package.json` e a pasta `public`. O HTML está em `public/index.html`.

**Não publique somente o HTML nem use o envio estático de um ZIP.** A privacidade solicitada depende do servidor. A instalação como aplicativo também depende dos arquivos de manifesto e serviço fornecidos pelo servidor.

Requisitos da hospedagem:

- Node.js 24, com suporte a `node:sqlite`;
- processo de servidor contínuo;
- disco persistente para o banco;
- domínio com HTTPS.

Hospedagem exclusivamente estática ou funções com disco temporário não são suficientes para este pacote. Há um Dockerfile incluído para hospedagens que aceitam contêineres.

## Primeira configuração

1. Extraia o ZIP e abra um terminal na pasta do projeto.
2. Execute `node scripts/create-admin.mjs`.
3. Informe seu nome completo (o padrão é Isabella Cleto) e escolha sua senha de seis números. Os números não aparecerão no terminal. O usuário será `isabella.cleto` se mantiver o nome padrão.
4. Execute `node server.mjs`.
5. Para testar no próprio computador, abra `http://localhost:3000`.
6. Acesse `http://localhost:3000/administracao/` e entre com sua conta.
7. Abra o Floratta e vá a **Proprietários e acessos** para cadastrar o primeiro gestor, corretores e proprietários.

Não há senha padrão nem conta administrativa pronta. O comando de configuração cria apenas uma administradora geral e se recusa a criar outra. Ele deve ser executado no mesmo ambiente e disco usado pelo servidor.

## Publicação

Configure no painel de sua hospedagem:

- Comando de início: `node server.mjs`.
- `PORT`: porta fornecida pela hospedagem (padrão local: 3000).
- `DATA_DIR`: caminho de uma pasta em disco persistente; o padrão é a pasta `data` do projeto.
- `PUBLIC_ORIGIN`: endereço exato do site com HTTPS, sem barra ao final. Exemplo: `https://bellos.seudominio.com.br`.
- `TRUST_PROXY=1`: somente quando a hospedagem estiver atrás de um proxy confiável que substitua o cabeçalho `X-Forwarded-For`. Caso contrário, mantenha 0. Esse ajuste influencia o limite de tentativas por conexão.

Execute o comando de criação da administradora no terminal da hospedagem, usando o mesmo `DATA_DIR`. A hospedagem deve encaminhar o cabeçalho Host original ou preservar o domínio configurado. Em produção os cookies são Secure e precisam de HTTPS.

Com Docker, crie a imagem a partir do Dockerfile, monte um volume persistente em `/app/data`, execute `node scripts/create-admin.mjs` no contêiner usando esse volume e inicie o servidor. Não crie contas durante o build da imagem.

Não envie `data/`, arquivos `.sqlite`, senhas ou arquivos de ambiente para uma pasta pública ou repositório. A pasta `public` contém apenas a interface e os materiais visuais.

## Cadastrar acessos

A administradora geral entra em `/administracao/`. Ela pode criar um empreendimento ou abrir o Floratta. Dentro de um empreendimento, **Proprietários e acessos** permite criar contas locais para aquele empreendimento.

- Gestores e administradora geral criam gestores, corretores e proprietários.
- Corretores criam e gerenciam somente os proprietários cadastrados por eles.
- O formulário gera o usuário e solicita uma senha inicial de seis números.
- Informe o usuário, a senha inicial e o endereço do empreendimento à pessoa por um canal privado. O sistema não envia mensagens automaticamente.
- No primeiro login, a pessoa precisa trocar a senha antes de acessar o painel.
- O mesmo nome em empreendimentos diferentes pode gerar o mesmo usuário: o empreendimento selecionado faz parte da identificação do acesso.
- Editar o nome não altera um usuário já criado. A função de redefinição cria uma senha temporária e revoga as sessões atuais.

## Instalar no dispositivo

Abra o endereço próprio, por exemplo `https://seu-dominio/e/floratta/`, usando HTTPS. Use **Adicionar este empreendimento ao dispositivo**. Quando houver suporte, aparecerá o diálogo de instalação. Se o navegador não oferecer esse diálogo, o botão mostra como usar a opção de instalação do navegador.

No iPhone/iPad, use Safari → Compartilhar → Adicionar à Tela de Início. Em navegadores compatíveis de desktop/notebook/Android, use Instalar aplicativo ou Adicionar à tela inicial. Cada empreendimento tem um manifesto, identidade e endereço inicial próprios. O suporte exato depende do navegador; algumas plataformas podem tratar o resultado como um atalho.

O aplicativo exige internet para entrar e consultar dados. Informações privadas e respostas da API não são armazenadas no cache do aplicativo. Ao abrir novamente, o usuário será direcionado ao login daquele empreendimento. A página de instalação do administrador geral orienta a abrir primeiro o endereço específico.

## Dados do Floratta e da versão anterior

A identidade visual, fotos, mapa realista e 112 lotes de referência foram preservados. As metragens e os valores continuam provisórios e precisam ser validados. As situações comerciais começam como disponíveis para cadastro; isso não confirma a disponibilidade real do empreendimento.

Esta versão não importa automaticamente o armazenamento local dos HTMLs anteriores. Clientes, senhas e vendas fictícias anteriores não foram transformados em contas reais. Antes de substituir uma versão antiga, exporte e guarde seu backup. O pacote começa sem gestores, corretores ou proprietários: você cria sua conta pelo comando inicial e cadastra os acessos depois.

O banco mantém os registros dos empreendimentos no servidor. Faça backup regular do volume de dados. Para uma cópia simples e consistente, pare o servidor e copie a pasta `data` inteira, incluindo arquivos auxiliares do SQLite; reinicie em seguida. Restaurar um backup deve ser feito com o servidor parado, preservando permissões da pasta.

## Limites dos módulos existentes

- Pix e boleto continuam demonstrativos: não há integração bancária nem cobrança real.
- Documentos armazenam títulos e referências dos arquivos, sem upload do conteúdo.
- Registros financeiros podem ser vinculados a um proprietário e a uma de suas unidades pelo formulário do gestor.
- Os percentuais ilustrativos de obras e as referências provisórias do mapa permanecem identificados na interface.
- As solicitações do proprietário chegam ao painel do gestor, que pode alterar o andamento.
- Não há recuperação automática por e-mail; a administração redefine a senha temporária.
- Trocas de perfil por seletor foram removidas da experiência de acesso. As permissões de leitura e escrita são conferidas na API, inclusive se alguém tentar acessar rotas diretamente.

## Verificação

Execute `node --test test/*.test.mjs`. Os testes cobrem login, troca obrigatória de senha, bloqueio de tentativas, isolamento entre empreendimentos, restrições por perfil, revogação de sessão, dados do proprietário, navegação das interfaces e manifestos por empreendimento.

Os testes de API e de interface em ambiente simulado foram executados. A aparência em navegador real e a instalação física em Android, iOS e desktop ainda precisam ser conferidas no domínio HTTPS de publicação.

Documentação técnica consultada: https://nodejs.org/api/sqlite.html ; https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Manifest/Reference/start_url ; https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Manifest/Reference/id .
