-- 1) Banco
CREATE DATABASE  escola_notas;

USE escola_notas;

-- 2) Tabelas

-- Alunos
CREATE TABLE IF NOT EXISTS alunos (
  id         BIGINT  AUTO_INCREMENT PRIMARY KEY,
  nome       VARCHAR(120) NOT NULL,
  matricula  VARCHAR(30)  NOT NULL UNIQUE
); 

-- Disciplinas
CREATE TABLE IF NOT EXISTS disciplinas (
  id      BIGINT AUTO_INCREMENT PRIMARY KEY,
  codigo  VARCHAR(20)  NOT NULL UNIQUE,
  nome    VARCHAR(160) NOT NULL
);

-- Turmas (oferta da disciplina por ano/semestre)
CREATE TABLE IF NOT EXISTS turmas (
  id             BIGINT AUTO_INCREMENT PRIMARY KEY,
  disciplina_id  BIGINT NOT NULL,
  ano            SMALLINT NOT NULL,
  semestre       TINYINT  NOT NULL,
  UNIQUE KEY uk_oferta (disciplina_id, ano, semestre),
  INDEX idx_turma_disciplina (disciplina_id),
  FOREIGN KEY (disciplina_id) REFERENCES disciplinas(id)
);

-- Matrículas do aluno na turma
CREATE TABLE IF NOT EXISTS matriculas (
  id         BIGINT  AUTO_INCREMENT PRIMARY KEY,
  turma_id   BIGINT  NOT NULL,
  aluno_id   BIGINT  NOT NULL,
  UNIQUE KEY uk_matricula (turma_id, aluno_id),
  INDEX idx_matricula_turma (turma_id),
  INDEX idx_matricula_aluno (aluno_id),
  FOREIGN KEY (turma_id) REFERENCES turmas(id),
  FOREIGN KEY (aluno_id) REFERENCES alunos(id)
);

-- Avaliações previstas na turma (com peso)
CREATE TABLE IF NOT EXISTS avaliacoes (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  turma_id      BIGINT NOT NULL,
  titulo        VARCHAR(120)    NOT NULL,
  peso_percent  DECIMAL(5,2)    NOT NULL,
  FOREIGN KEY (turma_id) REFERENCES turmas(id)
) ;

-- Notas lançadas por avaliação e matrícula
CREATE TABLE IF NOT EXISTS notas (
  id             BIGINT  AUTO_INCREMENT PRIMARY KEY,
  avaliacao_id   BIGINT  NOT NULL,
  matricula_id   BIGINT  NOT NULL,
  nota           DECIMAL(5,2)   NOT NULL, -- escala 0..10
  UNIQUE KEY uk_nota (avaliacao_id, matricula_id),
  INDEX idx_nota_avaliacao (avaliacao_id),
  INDEX idx_nota_matricula (matricula_id),
  FOREIGN KEY (avaliacao_id) REFERENCES avaliacoes(id),
  FOREIGN KEY (matricula_id) REFERENCES matriculas(id)
);

-- 4) Dados de exemplo mínimos (seed)

INSERT INTO alunos (nome, matricula) VALUES
('Carlos Souza', '2025A0001');

INSERT INTO disciplinas (codigo, nome) VALUES
('LP101', 'Linguagem de Programação I');

INSERT INTO turmas (disciplina_id, ano, semestre)
VALUES ((SELECT id FROM disciplinas WHERE codigo='LP101'), 2025, 1);

INSERT INTO matriculas (turma_id, aluno_id)
VALUES (
  (SELECT id FROM turmas WHERE disciplina_id = (SELECT id FROM disciplinas WHERE codigo='LP101') AND ano=2025 AND semestre=1),
  (SELECT id FROM alunos WHERE matricula='2025A0001')
);

-- Avaliações (pesos somando 100%)
INSERT INTO avaliacoes (turma_id, titulo, peso_percent) VALUES
((SELECT id FROM turmas LIMIT 1), 'Prova 1', 40.00),
((SELECT id FROM turmas LIMIT 1), 'Trabalho', 20.00),
((SELECT id FROM turmas LIMIT 1), 'Prova 2', 40.00);

-- Notas do aluno
INSERT INTO notas (avaliacao_id, matricula_id, nota)
SELECT a.id, m.id, 7.5
FROM avaliacoes a
JOIN matriculas m ON m.turma_id = a.turma_id
WHERE a.titulo='Prova 1';

INSERT INTO notas (avaliacao_id, matricula_id, nota)
SELECT a.id, m.id, 8.0
FROM avaliacoes a
JOIN matriculas m ON m.turma_id = a.turma_id
WHERE a.titulo='Trabalho';

INSERT INTO notas (avaliacao_id, matricula_id, nota)
SELECT a.id, m.id, 6.5
FROM avaliacoes a
JOIN matriculas m ON m.turma_id = a.turma_id
WHERE a.titulo='Prova 2';


