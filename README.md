
🏫 Sistema de Gestão de Notas de Alunos

Um sistema acadêmico simples desenvolvido em Python (Flask) com MySQL, que permite gerenciar alunos, disciplinas, turmas, matrículas, avaliações e notas.
Ideal como projeto de faculdade para a disciplina de Linguagem de Programação.

⚙️ 1. Requisitos

Python 3.10+

MySQL 8+

Pip instalado

VS Code ou MySQL Workbench

🗄️ 2. Configuração do Banco de Dados

Abra o MySQL Workbench (ou terminal MySQL).

Execute o script bd_escola.sql (ou equivalente):

        SOURCE C:/caminho/para/gestao-notas/bd_escola.sql;


Isso criará o banco escola_notas com todas as tabelas e dados de exemplo.

Verifique:

        USE escola_notas;
        SHOW TABLES;


Tabelas principais:

usuarios, professores, alunos, disciplinas,
turmas, matriculas, avaliacoes, notas

💻 3. Estrutura do Projeto
gestao-notas/
├── app.py
├── db.py
├── requirements.txt
├── bd_escola.sql
├── .env
└── templates/
    └── index.html

🔑 4. Arquivo .env

Crie na raiz do projeto o arquivo .env com as credenciais do seu MySQL:

DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=sua_senha
DB_NAME=escola_notas


Substitua sua_senha pela senha real do seu MySQL.

🧩 5. Ambiente Virtual e Instalação

No terminal (PowerShell ou VS Code):

cd "C:\Users\seu_usuario\Desktop\Sistema_Gestao_Notas_Alunos"
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt


Conteúdo mínimo do requirements.txt:

Flask==3.0.3
mysql-connector-python==9.0.0
python-dotenv==1.0.1

🚀 6. Executar o Sistema

Com o ambiente virtual ativo:

python app.py


Saída esperada:

 * Running on http://127.0.0.1:5000

🌐 7. Acesso no Navegador

Página inicial:
👉 http://127.0.0.1:5000

Interface simples (HTML):
👉 http://127.0.0.1:5000/ui

Verificar status da API:
👉 http://127.0.0.1:5000/health


O arquivo templates/index.html exibe dados básicos em listas e é carregado via /ui.

Para testar:

Suba o Flask (python app.py)

Acesse http://127.0.0.1:5000/ui

Clique em “Carregar Dados” — o HTML faz requisições fetch() à API e mostra os resultados.

<<<<<<< HEAD
=======

```
>>>>>>> 8583bc75bf2866e26fa7adf4b13c5d6575754401
