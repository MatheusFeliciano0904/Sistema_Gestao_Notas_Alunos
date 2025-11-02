# Sistema de Gestão de Notas de Alunos

Projeto desenvolvido para a disciplina de Linguagem de Programação, com o objetivo de criar um sistema simples de gerenciamento das notas dos alunos de uma instituição de ensino, utilizando Python (Flask) e MySQL.

---

## Tecnologias utilizadas

* Python 3.13 ou superior
* Flask
* MySQL
* mysql-connector-python
* python-dotenv
* Postman (para testes)

---

## Estrutura do projeto

```
gestao-notas/
│
├── app.py              # Código principal da API Flask
├── db.py               # Conexão com o banco de dados
├── bd_escola.sql       # Script de criação do banco e tabelas
├── .env                # Credenciais de acesso ao banco MySQL
├── requirements.txt    # Dependências do projeto
└── README.md           # Documento descritivo
```

---

## Banco de dados

Nome do banco: **escola_notas**

Tabelas principais:

* alunos
* disciplinas
* turmas
* matriculas
* avaliacoes
* notas

### Como criar o banco

1. Abra o MySQL Workbench
2. Conecte-se em localhost
3. Abra o arquivo `bd_escola.sql`
4. Clique no botão de execução (raio)
5. Verifique o schema `escola_notas` no painel lateral

---

## Arquivo .env

Crie um arquivo `.env` na raiz do projeto com os dados de acesso ao MySQL:

```
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=sua_senha
DB_NAME=escola_notas
```

---

## Executando o projeto

1. Ative o ambiente virtual

   ```
   .venv\Scripts\activate
   ```
2. Instale as dependências

   ```
   pip install -r requirements.txt
   ```
3. Execute o servidor

   ```
   python app.py
   ```
4. Acesse o sistema em

   ```
   http://127.0.0.1:5000
   ```

---

## Testes no Postman

Exemplos de rotas:

| Método | Endpoint                     | Descrição            |
| ------ | ---------------------------- | -------------------- |
| POST   | /alunos                      | Cadastrar aluno      |
| GET    | /alunos                      | Listar alunos        |
| POST   | /disciplinas                 | Cadastrar disciplina |
| POST   | /turmas                      | Criar turma          |
| POST   | /matriculas                  | Matricular aluno     |
| POST   | /avaliacoes                  | Cadastrar avaliações |
| POST   | /notas                       | Lançar notas         |
| GET    | /relatorios/turmas/1/medias  | Consultar médias     |
| GET    | /relatorios/alunos/1/boletim | Gerar boletim        |

---

## Testes realizados

No Postman foram testadas as operações de:

* Cadastro de alunos e disciplinas
* Criação de turmas e matrículas
* Lançamento de avaliações e notas
* Consulta de médias e boletins
* Integração entre Flask e MySQL

---

