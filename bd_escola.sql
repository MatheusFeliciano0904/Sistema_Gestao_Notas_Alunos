-- 1) Banco
CREATE DATABASE  escola_notas;

USE escola_notas;

-- 2) Tabelas
-- (Opcional) Zera o banco:
-- DROP DATABASE IF EXISTS escola_notas;

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
) ENGINE=InnoDB;

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

-- Usuários (1 admin, 1 professor e 2 alunos)
INSERT INTO usuarios (nome, email, senha_hash, perfil) VALUES
('Administrador', 'admin@escola.com', 'hash_admin', 'ADMIN'),
('João Professor', 'joao.prof@escola.com', 'hash_professor', 'PROFESSOR'),
('Maria da Silva', 'maria.aluna@escola.com', 'hash_aluno1', 'ALUNO'),
('Carlos Souza', 'carlos.aluno@escola.com', 'hash_aluno2', 'ALUNO');

-- Professores (referencia o usuário de perfil PROFESSOR)
INSERT INTO professores (usuario_id, titulacao) VALUES
((SELECT id FROM usuarios WHERE email='joao.prof@escola.com'), 'Mestre em Computação');

-- Alunos (vinculados aos usuários de perfil ALUNO)
INSERT INTO alunos (nome, matricula, usuario_id) VALUES
('Maria da Silva', '2025A0001', (SELECT id FROM usuarios WHERE email='maria.aluna@escola.com')),
('Carlos Souza', '2025A0002', (SELECT id FROM usuarios WHERE email='carlos.aluno@escola.com'));

-- Disciplinas
INSERT INTO disciplinas (codigo, nome) VALUES
('LP101', 'Linguagem de Programação I'),
('BD101', 'Banco de Dados I');

-- Turmas (com professor responsável)
INSERT INTO turmas (disciplina_id, professor_id, ano, semestre)
VALUES
((SELECT id FROM disciplinas WHERE codigo='LP101'),
 (SELECT usuario_id FROM professores WHERE usuario_id=(SELECT id FROM usuarios WHERE email='joao.prof@escola.com')),
 2025, 1);

-- Matrículas
INSERT INTO matriculas (turma_id, aluno_id) VALUES
((SELECT id FROM turmas WHERE disciplina_id=(SELECT id FROM disciplinas WHERE codigo='LP101')), 
 (SELECT id FROM alunos WHERE matricula='2025A0001')),
((SELECT id FROM turmas WHERE disciplina_id=(SELECT id FROM disciplinas WHERE codigo='LP101')), 
 (SELECT id FROM alunos WHERE matricula='2025A0002'));

-- Avaliações (peso somando 100%)
INSERT INTO avaliacoes (turma_id, titulo, peso_percent) VALUES
((SELECT id FROM turmas WHERE disciplina_id=(SELECT id FROM disciplinas WHERE codigo='LP101')), 'Prova 1', 40.00),
((SELECT id FROM turmas WHERE disciplina_id=(SELECT id FROM disciplinas WHERE codigo='LP101')), 'Trabalho', 20.00),
((SELECT id FROM turmas WHERE disciplina_id=(SELECT id FROM disciplinas WHERE codigo='LP101')), 'Prova 2', 40.00);

-- Notas
INSERT INTO notas (avaliacao_id, matricula_id, nota)
SELECT a.id, m.id, 8.5
FROM avaliacoes a
JOIN matriculas m ON m.turma_id = a.turma_id
WHERE a.titulo='Prova 1';

INSERT INTO notas (avaliacao_id, matricula_id, nota)
SELECT a.id, m.id, 7.5
FROM avaliacoes a
JOIN matriculas m ON m.turma_id = a.turma_id
WHERE a.titulo='Trabalho';

INSERT INTO notas (avaliacao_id, matricula_id, nota)
SELECT a.id, m.id, 9.0
FROM avaliacoes a
JOIN matriculas m ON m.turma_id = a.turma_id
WHERE a.titulo='Prova 2';



