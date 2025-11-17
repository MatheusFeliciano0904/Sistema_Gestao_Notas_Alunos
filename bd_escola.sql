





CREATE DATABASE IF NOT EXISTS escola_notas;

USE escola_notas;

-- USUÁRIOS / PERFIS
CREATE TABLE IF NOT EXISTS usuarios (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  nome          VARCHAR(120)       NOT NULL,
  email         VARCHAR(160)       NOT NULL UNIQUE,
  senha_hash    VARCHAR(255)       NOT NULL,
  perfil        ENUM('ALUNO','PROFESSOR','ADMIN') NOT NULL,
  ativo         TINYINT(1)         NOT NULL DEFAULT 1,
  criado_em     TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS professores (
  usuario_id  BIGINT PRIMARY KEY,
  titulacao   VARCHAR(120) NULL,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- ALUNOS
CREATE TABLE IF NOT EXISTS alunos (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY,
  nome         VARCHAR(120) NOT NULL,
  matricula    VARCHAR(30)  NOT NULL UNIQUE,
  usuario_id   BIGINT NULL UNIQUE,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ;

-- DISCIPLINAS
CREATE TABLE IF NOT EXISTS disciplinas (
  id      BIGINT AUTO_INCREMENT PRIMARY KEY,
  codigo  VARCHAR(20)  NOT NULL UNIQUE,
  nome    VARCHAR(160) NOT NULL
);

-- TURMAS
CREATE TABLE IF NOT EXISTS turmas (
  id             BIGINT AUTO_INCREMENT PRIMARY KEY,
  disciplina_id  BIGINT NOT NULL,
  professor_id   BIGINT NULL,      -- professor responsável (opcional no início)
  ano            SMALLINT NOT NULL,
  semestre       TINYINT  NOT NULL,
  UNIQUE KEY uk_oferta (disciplina_id, ano, semestre),
  INDEX idx_turma_disciplina (disciplina_id),
  INDEX idx_turma_professor (professor_id),
  FOREIGN KEY (disciplina_id) REFERENCES disciplinas(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (professor_id) REFERENCES professores(usuario_id)
    ON UPDATE CASCADE ON DELETE SET NULL
);

-- MATRÍCULAS
CREATE TABLE IF NOT EXISTS matriculas (
  id         BIGINT  AUTO_INCREMENT PRIMARY KEY,
  turma_id   BIGINT  NOT NULL,
  aluno_id   BIGINT  NOT NULL,
  UNIQUE KEY uk_matricula (turma_id, aluno_id),
  INDEX idx_matricula_turma (turma_id),
  INDEX idx_matricula_aluno (aluno_id),
  FOREIGN KEY (turma_id) REFERENCES turmas(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (aluno_id) REFERENCES alunos(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
);

-- AVALIAÇÕES
CREATE TABLE IF NOT EXISTS avaliacoes (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  turma_id      BIGINT NOT NULL,
  titulo        VARCHAR(120) NOT NULL,
  peso_percent  DECIMAL(5,2) NOT NULL,
  INDEX idx_avaliacoes_turma (turma_id),
  FOREIGN KEY (turma_id) REFERENCES turmas(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  UNIQUE KEY uk_avaliacao_turma_titulo (turma_id, titulo)
);

-- NOTAS
CREATE TABLE IF NOT EXISTS notas (
  id             BIGINT  AUTO_INCREMENT PRIMARY KEY,
  avaliacao_id   BIGINT  NOT NULL,
  matricula_id   BIGINT  NOT NULL,
  nota           DECIMAL(5,2)   NOT NULL,
  UNIQUE KEY uk_nota (avaliacao_id, matricula_id),
  INDEX idx_nota_avaliacao (avaliacao_id),
  INDEX idx_nota_matricula (matricula_id),
  FOREIGN KEY (avaliacao_id) REFERENCES avaliacoes(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (matricula_id) REFERENCES matriculas(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_nota_0_10 CHECK (nota >= 0 AND nota <= 10)
);

USE escola_notas;


/* =====================================================
   USUÁRIOS (ADMIN, PROFESSORES, ALUNOS)
   As senhas já estão em SHA-256:
   Senha padrão usada: 123456
===================================================== */

INSERT INTO usuarios (nome, email, senha_hash, perfil) VALUES
('Administrador Geral', 'admin@escola.com',
 '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'ADMIN'),

('Prof. João Mendes', 'joao.prof@escola.com',
 '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'PROFESSOR'),

('Prof. Carla Ribeiro', 'carla.prof@escola.com',
 '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'PROFESSOR'),

('Maria da Silva', 'maria.aluna@escola.com',
 '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'ALUNO'),

('Carlos Souza', 'carlos.aluno@escola.com',
 '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'ALUNO');



/* =====================================================
   PROFESSORES
===================================================== */
INSERT INTO professores (usuario_id, titulacao) VALUES
((SELECT id FROM usuarios WHERE email='joao.prof@escola.com'), 'Mestre em Computação'),
((SELECT id FROM usuarios WHERE email='carla.prof@escola.com'), 'Doutora em Sistemas de Informação');



/* =========================
   ALUNOS, DISCIPLINAS, TURMAS, MATRÍCULAS, AVALIAÇÕES E NOTAS
   (com notas diferentes para cada aluno)
   ========================= */

-- Alunos vinculados aos usuários já existentes
INSERT INTO alunos (nome, matricula, usuario_id) VALUES
('Maria da Silva',  '2025A0001', (SELECT id FROM usuarios WHERE email='maria.aluna@escola.com')),
('Carlos Souza',    '2025A0002', (SELECT id FROM usuarios WHERE email='carlos.aluno@escola.com'));

-- Disciplinas
INSERT INTO disciplinas (codigo, nome) VALUES
('LP101', 'Linguagem de Programação I'),
('BD101', 'Banco de Dados I');

-- Turma de LP101 (2025/1)
INSERT INTO turmas (disciplina_id, professor_id, ano, semestre) VALUES
(
  (SELECT id FROM disciplinas WHERE codigo = 'LP101'),
  (SELECT usuario_id FROM professores LIMIT 1),
  2025, 1
);

-- Turma de BD101 (2025/1)
INSERT INTO turmas (disciplina_id, professor_id, ano, semestre) VALUES
(
  (SELECT id FROM disciplinas WHERE codigo = 'BD101'),
  (SELECT usuario_id FROM professores LIMIT 1),
  2025, 1
);

-- Matrículas:
-- Maria e Carlos em LP101
INSERT INTO matriculas (turma_id, aluno_id) VALUES
(
  (SELECT t.id FROM turmas t JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'LP101' AND t.ano = 2025 AND t.semestre = 1),
  (SELECT id FROM alunos WHERE matricula = '2025A0001')
),
(
  (SELECT t.id FROM turmas t JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'LP101' AND t.ano = 2025 AND t.semestre = 1),
  (SELECT id FROM alunos WHERE matricula = '2025A0002')
);

-- Maria e Carlos em BD101
INSERT INTO matriculas (turma_id, aluno_id) VALUES
(
  (SELECT t.id FROM turmas t JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'BD101' AND t.ano = 2025 AND t.semestre = 1),
  (SELECT id FROM alunos WHERE matricula = '2025A0001')
),
(
  (SELECT t.id FROM turmas t JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'BD101' AND t.ano = 2025 AND t.semestre = 1),
  (SELECT id FROM alunos WHERE matricula = '2025A0002')
);

-- Avaliações de LP101 (pesos somando 100%)
INSERT INTO avaliacoes (turma_id, titulo, peso_percent) VALUES
(
  (SELECT t.id FROM turmas t JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'LP101' AND t.ano = 2025 AND t.semestre = 1),
  'Prova 1', 40.00
),
(
  (SELECT t.id FROM turmas t JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'LP101' AND t.ano = 2025 AND t.semestre = 1),
  'Trabalho', 20.00
),
(
  (SELECT t.id FROM turmas t JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'LP101' AND t.ano = 2025 AND t.semestre = 1),
  'Prova 2', 40.00
);

-- Avaliações de BD101 (mesma distribuição de pesos)
INSERT INTO avaliacoes (turma_id, titulo, peso_percent) VALUES
(
  (SELECT t.id FROM turmas t JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'BD101' AND t.ano = 2025 AND t.semestre = 1),
  'Prova 1', 40.00
),
(
  (SELECT t.id FROM turmas t JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'BD101' AND t.ano = 2025 AND t.semestre = 1),
  'Trabalho', 20.00
),
(
  (SELECT t.id FROM turmas t JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'BD101' AND t.ano = 2025 AND t.semestre = 1),
  'Prova 2', 40.00
);

-- ========================
-- NOTAS DIFERENTES POR ALUNO
-- ========================

/* Para facilitar, vamos usar subselects que pegam:
   - id da avaliação (por título + disciplina + ano/semestre)
   - id da matrícula (por disciplina + aluno)
*/

/* -------- LP101 (Linguagem de Programação I) -------- */

-- Maria (2025A0001) em LP101:
-- Prova 1: 9.0, Trabalho: 8.0, Prova 2: 9.5

INSERT INTO notas (avaliacao_id, matricula_id, nota) VALUES
(
  -- Prova 1 - LP101 - Maria
  (SELECT av.id
   FROM avaliacoes av
   JOIN turmas t   ON t.id = av.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'LP101' AND av.titulo = 'Prova 1'
         AND t.ano = 2025 AND t.semestre = 1),
  (SELECT m.id
   FROM matriculas m
   JOIN turmas t   ON t.id = m.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   JOIN alunos a   ON a.id = m.aluno_id
   WHERE d.codigo = 'LP101' AND a.matricula = '2025A0001'
         AND t.ano = 2025 AND t.semestre = 1),
  9.0
),
(
  -- Trabalho - LP101 - Maria
  (SELECT av.id
   FROM avaliacoes av
   JOIN turmas t   ON t.id = av.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'LP101' AND av.titulo = 'Trabalho'
         AND t.ano = 2025 AND t.semestre = 1),
  (SELECT m.id
   FROM matriculas m
   JOIN turmas t   ON t.id = m.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   JOIN alunos a   ON a.id = m.aluno_id
   WHERE d.codigo = 'LP101' AND a.matricula = '2025A0001'
         AND t.ano = 2025 AND t.semestre = 1),
  8.0
),
(
  -- Prova 2 - LP101 - Maria
  (SELECT av.id
   FROM avaliacoes av
   JOIN turmas t   ON t.id = av.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'LP101' AND av.titulo = 'Prova 2'
         AND t.ano = 2025 AND t.semestre = 1),
  (SELECT m.id
   FROM matriculas m
   JOIN turmas t   ON t.id = m.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   JOIN alunos a   ON a.id = m.aluno_id
   WHERE d.codigo = 'LP101' AND a.matricula = '2025A0001'
         AND t.ano = 2025 AND t.semestre = 1),
  9.5
);

-- Carlos (2025A0002) em LP101:
-- Prova 1: 7.0, Trabalho: 6.5, Prova 2: 8.0

INSERT INTO notas (avaliacao_id, matricula_id, nota) VALUES
(
  -- Prova 1 - LP101 - Carlos
  (SELECT av.id
   FROM avaliacoes av
   JOIN turmas t   ON t.id = av.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'LP101' AND av.titulo = 'Prova 1'
         AND t.ano = 2025 AND t.semestre = 1),
  (SELECT m.id
   FROM matriculas m
   JOIN turmas t   ON t.id = m.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   JOIN alunos a   ON a.id = m.aluno_id
   WHERE d.codigo = 'LP101' AND a.matricula = '2025A0002'
         AND t.ano = 2025 AND t.semestre = 1),
  7.0
),
(
  -- Trabalho - LP101 - Carlos
  (SELECT av.id
   FROM avaliacoes av
   JOIN turmas t   ON t.id = av.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'LP101' AND av.titulo = 'Trabalho'
         AND t.ano = 2025 AND t.semestre = 1),
  (SELECT m.id
   FROM matriculas m
   JOIN turmas t   ON t.id = m.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   JOIN alunos a   ON a.id = m.aluno_id
   WHERE d.codigo = 'LP101' AND a.matricula = '2025A0002'
         AND t.ano = 2025 AND t.semestre = 1),
  6.5
),
(
  -- Prova 2 - LP101 - Carlos
  (SELECT av.id
   FROM avaliacoes av
   JOIN turmas t   ON t.id = av.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'LP101' AND av.titulo = 'Prova 2'
         AND t.ano = 2025 AND t.semestre = 1),
  (SELECT m.id
   FROM matriculas m
   JOIN turmas t   ON t.id = m.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   JOIN alunos a   ON a.id = m.aluno_id
   WHERE d.codigo = 'LP101' AND a.matricula = '2025A0002'
         AND t.ano = 2025 AND t.semestre = 1),
  8.0
);

/* -------- BD101 (Banco de Dados I) -------- */

-- Para BD101, vamos usar outro conjunto de notas,
-- também diferentes entre Maria e Carlos.

-- Maria em BD101:
-- Prova 1: 8.0, Trabalho: 9.0, Prova 2: 8.5
INSERT INTO notas (avaliacao_id, matricula_id, nota) VALUES
(
  -- Prova 1 - BD101 - Maria
  (SELECT av.id
   FROM avaliacoes av
   JOIN turmas t   ON t.id = av.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'BD101' AND av.titulo = 'Prova 1'
         AND t.ano = 2025 AND t.semestre = 1),
  (SELECT m.id
   FROM matriculas m
   JOIN turmas t   ON t.id = m.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   JOIN alunos a   ON a.id = m.aluno_id
   WHERE d.codigo = 'BD101' AND a.matricula = '2025A0001'
         AND t.ano = 2025 AND t.semestre = 1),
  8.0
),
(
  -- Trabalho - BD101 - Maria
  (SELECT av.id
   FROM avaliacoes av
   JOIN turmas t   ON t.id = av.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'BD101' AND av.titulo = 'Trabalho'
         AND t.ano = 2025 AND t.semestre = 1),
  (SELECT m.id
   FROM matriculas m
   JOIN turmas t   ON t.id = m.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   JOIN alunos a   ON a.id = m.aluno_id
   WHERE d.codigo = 'BD101' AND a.matricula = '2025A0001'
         AND t.ano = 2025 AND t.semestre = 1),
  9.0
),
(
  -- Prova 2 - BD101 - Maria
  (SELECT av.id
   FROM avaliacoes av
   JOIN turmas t   ON t.id = av.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'BD101' AND av.titulo = 'Prova 2'
         AND t.ano = 2025 AND t.semestre = 1),
  (SELECT m.id
   FROM matriculas m
   JOIN turmas t   ON t.id = m.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   JOIN alunos a   ON a.id = m.aluno_id
   WHERE d.codigo = 'BD101' AND a.matricula = '2025A0001'
         AND t.ano = 2025 AND t.semestre = 1),
  8.5
);

-- Carlos em BD101:
-- Prova 1: 6.0, Trabalho: 7.0, Prova 2: 6.5
INSERT INTO notas (avaliacao_id, matricula_id, nota) VALUES
(
  -- Prova 1 - BD101 - Carlos
  (SELECT av.id
   FROM avaliacoes av
   JOIN turmas t   ON t.id = av.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'BD101' AND av.titulo = 'Prova 1'
         AND t.ano = 2025 AND t.semestre = 1),
  (SELECT m.id
   FROM matriculas m
   JOIN turmas t   ON t.id = m.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   JOIN alunos a   ON a.id = m.aluno_id
   WHERE d.codigo = 'BD101' AND a.matricula = '2025A0002'
         AND t.ano = 2025 AND t.semestre = 1),
  6.0
),
(
  -- Trabalho - BD101 - Carlos
  (SELECT av.id
   FROM avaliacoes av
   JOIN turmas t   ON t.id = av.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'BD101' AND av.titulo = 'Trabalho'
         AND t.ano = 2025 AND t.semestre = 1),
  (SELECT m.id
   FROM matriculas m
   JOIN turmas t   ON t.id = m.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   JOIN alunos a   ON a.id = m.aluno_id
   WHERE d.codigo = 'BD101' AND a.matricula = '2025A0002'
         AND t.ano = 2025 AND t.semestre = 1),
  7.0
),
(
  -- Prova 2 - BD101 - Carlos
  (SELECT av.id
   FROM avaliacoes av
   JOIN turmas t   ON t.id = av.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   WHERE d.codigo = 'BD101' AND av.titulo = 'Prova 2'
         AND t.ano = 2025 AND t.semestre = 1),
  (SELECT m.id
   FROM matriculas m
   JOIN turmas t   ON t.id = m.turma_id
   JOIN disciplinas d ON d.id = t.disciplina_id
   JOIN alunos a   ON a.id = m.aluno_id
   WHERE d.codigo = 'BD101' AND a.matricula = '2025A0002'
         AND t.ano = 2025 AND t.semestre = 1),
  6.5
);

-- FIM DOS DADOS DE EXEMPLO

