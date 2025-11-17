# 📚 Sistema de Gestão de Notas de Alunos

Projeto acadêmico desenvolvido para a disciplina **Linguagem de Programação**, utilizando:

- **Python + Flask** (backend)
- **MySQL** (banco de dados)
- **HTML + CSS + JavaScript** (frontend simples via Flask templates)

O sistema permite:

✔ Cadastro de alunos  
✔ Cadastro de disciplinas  
✔ Cadastro de turmas  
✔ Matrículas  
✔ Criação de avaliações  
✔ Lançamento de notas  
✔ Geração de boletim  
✔ Gráfico de médias do aluno  


## 🚀 1. Requisitos

Antes de rodar o projeto, instale:

- Python 3.x  
- MySQL Server (ou Workbench)  
- pip (gerenciador de pacotes do Python)  


## 🗄 2. Criar o Banco de Dados

Abra o MySQL Workbench ou outro cliente SQL e execute o arquivo:

``script.sql``

Ele criará o banco **escola_notas**, tabelas, relacionamentos e dados de exemplo.


## 📁 3. Estrutura do Projeto
```
Sistema_Gestao_Notas_Alunos/
│── app.py
│── db.py
│── script.sql
│── .env ← será criado no próximo passo
│── requirements.txt ← opcional
└── templates/
│── index.html
│── boletim.html
└── grafico.html
```



## 🔧 4. Configurar o Acesso ao Banco (.env)

Na raiz do projeto, crie o arquivo **.env** com:
```
DB_HOST=localhost
DB_USER=root
DB_PASS=sua_senha_do_mysql
DB_NAME=escola_notas
```


⚠ O nome do banco deve ser exatamente **escola_notas**.


## 🧪 5. Criar o Ambiente Virtual (venv)

No terminal, dentro da pasta do projeto:

### 5.1 Criar venv
```
python -m venv venv
```

### 5.2 Ativar venv

Windows:
```
venv\Scripts\activate
```

## 📦 6. Instalar Dependências

Com o venv ativo:

```
pip install -r requirements.txt
```



## ▶ 7. Executar a Aplicação

```
python app.py
```



A aplicação iniciará em:

http://localhost:5000

A interface estará em:

http://localhost:5000/ui


## 🎉 Pronto!

O sistema está funcionando completamente!
