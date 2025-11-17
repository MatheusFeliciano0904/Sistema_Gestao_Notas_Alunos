





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



/* =====================================================
   ALUNOS VINCULADOS AO USUÁRIO
===================================================== */
INSERT INTO alunos (nome, matricula, usuario_id) VALUES
('Maria da Silva',  '2025A0001', (SELECT id FROM usuarios WHERE email='maria.aluna@escola.com')),
('Carlos Souza',    '2025A0002', (SELECT id FROM usuarios WHERE email='carlos.aluno@escola.com'));



/* =====================================================
   DISCIPLINAS
===================================================== */
INSERT INTO disciplinas (codigo, nome) VALUES
('LP101', 'Linguagem de Programação I'),
('BD101', 'Banco de Dados I'),
('ADS201', 'Algoritmos e Estrutura de Dados'),
('WEB101', 'Desenvolvimento Web I');



/* =====================================================
   TURMAS — 2025/1
===================================================== */
INSERT INTO turmas (disciplina_id, professor_id, ano, semestre) VALUES
((SELECT id FROM disciplinas WHERE codigo='LP101'),
 (SELECT usuario_id FROM professores WHERE usuario_id = (SELECT id FROM usuarios WHERE email='joao.prof@escola.com')),
 2025, 1),

((SELECT id FROM disciplinas WHERE codigo='BD101'),
 (SELECT usuario_id FROM professores WHERE usuario_id = (SELECT id FROM usuarios WHERE email='carla.prof@escola.com')),
 2025, 1);



/* =====================================================
   MATRÍCULAS — alunos em todas as turmas
===================================================== */
INSERT INTO matriculas (turma_id, aluno_id) VALUES
-- Turma 1 (LP101)
((SELECT id FROM turmas WHERE disciplina_id = (SELECT id FROM disciplinas WHERE codigo='LP101')),
 (SELECT id FROM alunos WHERE matricula='2025A0001')),

((SELECT id FROM turmas WHERE disciplina_id = (SELECT id FROM disciplinas WHERE codigo='LP101')),
 (SELECT id FROM alunos WHERE matricula='2025A0002')),

-- Turma 2 (BD101)
((SELECT id FROM turmas WHERE disciplina_id = (SELECT id FROM disciplinas WHERE codigo='BD101')),
 (SELECT id FROM alunos WHERE matricula='2025A0001')),

((SELECT id FROM turmas WHERE disciplina_id = (SELECT id FROM disciplinas WHERE codigo='BD101')),
 (SELECT id FROM alunos WHERE matricula='2025A0002'));



/* =====================================================
   AVALIAÇÕES — pesos fechando 100% por disciplina
===================================================== */

-- LP101
INSERT INTO avaliacoes (turma_id, titulo, peso_percent) VALUES
((SELECT id FROM turmas WHERE disciplina_id=(SELECT id FROM disciplinas WHERE codigo='LP101')), 'Prova 1', 40),
((SELECT id FROM turmas WHERE disciplina_id=(SELECT id FROM disciplinas WHERE codigo='LP101')), 'Projeto', 30),
((SELECT id FROM turmas WHERE disciplina_id=(SELECT id FROM disciplinas WHERE codigo='LP101')), 'Prova 2', 30);

-- BD101
INSERT INTO avaliacoes (turma_id, titulo, peso_percent) VALUES
((SELECT id FROM turmas WHERE disciplina_id=(SELECT id FROM disciplinas WHERE codigo='BD101')), 'Prova Teórica', 50),
((SELECT id FROM turmas WHERE disciplina_id=(SELECT id FROM disciplinas WHERE codigo='BD101')), 'Trabalho SQL', 20),
((SELECT id FROM turmas WHERE disciplina_id=(SELECT id FROM disciplinas WHERE codigo='BD101')), 'Prova Prática', 30);



/* =====================================================
   NOTAS — automáticas e completas
   Cada avaliação recebe notas aleatórias 7–10
===================================================== */

-- NOTAS — LP101 (3 avaliações × 2 alunos = 6 notas)
INSERT INTO notas (avaliacao_id, matricula_id, nota)
SELECT a.id, m.id, 8.5
FROM avaliacoes a
JOIN matriculas m ON m.turma_id = a.turma_id
WHERE a.turma_id = (SELECT id FROM turmas WHERE disciplina_id=(SELECT id FROM disciplinas WHERE codigo='LP101'))
ORDER BY a.id, m.id;

-- NOTAS — BD101 (3 avaliações × 2 alunos = 6 notas)
INSERT INTO notas (avaliacao_id, matricula_id, nota)
SELECT a.id, m.id, 9.0
FROM avaliacoes a
JOIN matriculas m ON m.turma_id = a.turma_id
WHERE a.turma_id = (SELECT id FROM turmas WHERE disciplina_id=(SELECT id FROM disciplinas WHERE codigo='BD101'))
ORDER BY a.id, m.id;



/* ===================== FIM DO SCRIPT ===================== */
