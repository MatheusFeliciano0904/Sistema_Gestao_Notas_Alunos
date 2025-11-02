from flask import Flask, jsonify, request
from db import query, execute

app = Flask(__name__)

def required_fields(data, fields):
    """Valida campos obrigatórios no JSON."""
    missing = [f for f in fields if f not in data or data[f] in (None, "")]
    if missing:
        return f"Campos obrigatórios ausentes: {', '.join(missing)}"
    return None

@app.get("/health")
def health():
    return {"status": "ok"}, 200

@app.route("/")
def index():
    return """
    <h2>API de Gestão de Notas</h2>
    <p>Bem-vindo! Use os links abaixo para testar os endpoints:</p>
    <ul>
        <li><a href="/health">/health</a> – Teste de conexão</li>
        <li><a href="/alunos">/alunos</a> – Listar alunos (GET)</li>
        <li><a href="/disciplinas">/disciplinas</a> – Listar disciplinas (GET)</li>
        <li><a href="/turmas">/turmas</a> – Listar turmas (GET)</li>
        <li><a href="/avaliacoes">/avaliacoes</a> – Listar avaliações (GET)</li>
        <li><a href="/notas">/notas</a> – Listar notas (GET)</li>
    </ul>
    <p>Use ferramentas como <strong>Postman</strong> ou <strong>Insomnia</strong> para testar os endpoints POST.</p>
    """



# -----------------------------
# ALUNOS
# -----------------------------
@app.post("/alunos")
def create_aluno():
    """
    JSON esperado: { "nome": "...", "matricula": "..." }
    """
    data = request.get_json(force=True)
    err = required_fields(data, ["nome", "matricula"])
    if err:
        return {"erro": err}, 400

    try:
        sql = "INSERT INTO alunos (nome, matricula) VALUES (%s, %s)"
        last_id = execute(sql, (data["nome"], data["matricula"]), return_last_id=True)
        aluno = query("SELECT * FROM alunos WHERE id=%s", (last_id,))
        return aluno[0], 201
    except Exception as e:
        return {"erro": str(e)}, 400

@app.get("/alunos")
def list_alunos():
    alunos = query("SELECT * FROM alunos ORDER BY id DESC")
    return jsonify(alunos)

@app.get("/alunos/<int:aluno_id>")
def get_aluno(aluno_id):
    rows = query("SELECT * FROM alunos WHERE id=%s", (aluno_id,))
    if not rows:
        return {"erro": "Aluno não encontrado"}, 404
    return rows[0]

@app.put("/alunos/<int:aluno_id>")
def update_aluno(aluno_id):
    data = request.get_json(force=True)
    # Atualização simples: permite trocar nome e/ou matricula
    sql = "UPDATE alunos SET nome=%s, matricula=%s WHERE id=%s"
    count = execute(sql, (data.get("nome"), data.get("matricula"), aluno_id))
    if count == 0:
        return {"erro": "Aluno não encontrado"}, 404
    return get_aluno(aluno_id)

@app.delete("/alunos/<int:aluno_id>")
def delete_aluno(aluno_id):
    count = execute("DELETE FROM alunos WHERE id=%s", (aluno_id,))
    if count == 0:
        return {"erro": "Aluno não encontrado"}, 404
    return {"ok": True}

# -----------------------------
# DISCIPLINAS
# -----------------------------
@app.post("/disciplinas")
def create_disciplina():
    data = request.get_json(force=True)
    err = required_fields(data, ["codigo", "nome"])
    if err:
        return {"erro": err}, 400
    try:
        last_id = execute(
            "INSERT INTO disciplinas (codigo, nome) VALUES (%s, %s)",
            (data["codigo"], data["nome"]), return_last_id=True
        )
        row = query("SELECT * FROM disciplinas WHERE id=%s", (last_id,))
        return row[0], 201
    except Exception as e:
        return {"erro": str(e)}, 400

@app.get("/disciplinas")
def list_disciplinas():
    return jsonify(query("SELECT * FROM disciplinas ORDER BY id DESC"))

# -----------------------------
# TURMAS
# -----------------------------
@app.post("/turmas")
def create_turma():
    """
    JSON: { "disciplina_id": 1, "ano": 2025, "semestre": 1 }
    """
    data = request.get_json(force=True)
    err = required_fields(data, ["disciplina_id", "ano", "semestre"])
    if err:
        return {"erro": err}, 400
    try:
        last_id = execute(
            "INSERT INTO turmas (disciplina_id, ano, semestre) VALUES (%s,%s,%s)",
            (data["disciplina_id"], data["ano"], data["semestre"]),
            return_last_id=True
        )
        turma = query("""
            SELECT t.*, d.codigo AS disciplina_codigo, d.nome AS disciplina_nome
            FROM turmas t JOIN disciplinas d ON d.id=t.disciplina_id
            WHERE t.id=%s
        """, (last_id,))
        return turma[0], 201
    except Exception as e:
        return {"erro": str(e)}, 400

@app.get("/turmas")
def list_turmas():
    return jsonify(query("""
        SELECT t.*, d.codigo AS disciplina_codigo, d.nome AS disciplina_nome
        FROM turmas t JOIN disciplinas d ON d.id=t.disciplina_id
        ORDER BY t.id DESC
    """))

# -----------------------------
# MATRICULAS
# -----------------------------
@app.post("/matriculas")
def create_matricula():
    """
    JSON: { "turma_id": 1, "aluno_id": 1 }
    """
    data = request.get_json(force=True)
    err = required_fields(data, ["turma_id", "aluno_id"])
    if err:
        return {"erro": err}, 400
    try:
        last_id = execute(
            "INSERT INTO matriculas (turma_id, aluno_id) VALUES (%s,%s)",
            (data["turma_id"], data["aluno_id"]), return_last_id=True
        )
        return query("SELECT * FROM matriculas WHERE id=%s", (last_id,))[0], 201
    except Exception as e:
        return {"erro": str(e)}, 400

@app.get("/matriculas")
def list_matriculas():
    return jsonify(query("""
        SELECT m.*, a.nome AS aluno_nome, a.matricula AS aluno_matricula,
               d.codigo AS disciplina_codigo, d.nome AS disciplina_nome, t.ano, t.semestre
        FROM matriculas m
        JOIN alunos a ON a.id=m.aluno_id
        JOIN turmas t ON t.id=m.turma_id
        JOIN disciplinas d ON d.id=t.disciplina_id
        ORDER BY m.id DESC
    """))

# -----------------------------
# AVALIAÇÕES
# -----------------------------
@app.post("/avaliacoes")
def create_avaliacao():
    """
    JSON: { "turma_id": 1, "titulo": "Prova 1", "peso_percent": 40.0 }
    """
    data = request.get_json(force=True)
    err = required_fields(data, ["turma_id", "titulo", "peso_percent"])
    if err:
        return {"erro": err}, 400
    try:
        last_id = execute(
            "INSERT INTO avaliacoes (turma_id, titulo, peso_percent) VALUES (%s,%s,%s)",
            (data["turma_id"], data["titulo"], data["peso_percent"]),
            return_last_id=True
        )
        return query("SELECT * FROM avaliacoes WHERE id=%s", (last_id,))[0], 201
    except Exception as e:
        return {"erro": str(e)}, 400

@app.get("/avaliacoes")
def list_avaliacoes():
    turma_id = request.args.get("turma_id")
    if turma_id:
        return jsonify(query("SELECT * FROM avaliacoes WHERE turma_id=%s", (turma_id,)))
    return jsonify(query("SELECT * FROM avaliacoes ORDER BY id DESC"))

# -----------------------------
# NOTAS
# -----------------------------
@app.post("/notas")
def lancar_nota():
    """
    Lança ou atualiza nota (simples).
    JSON: { "avaliacao_id": 1, "matricula_id": 1, "nota": 7.5 }
    """
    data = request.get_json(force=True)
    err = required_fields(data, ["avaliacao_id", "matricula_id", "nota"])
    if err:
        return {"erro": err}, 400

    try:
        # "UPSERT" simples usando chave única (avaliacao_id, matricula_id)
        sql = """
            INSERT INTO notas (avaliacao_id, matricula_id, nota)
            VALUES (%s,%s,%s)
            ON DUPLICATE KEY UPDATE nota=VALUES(nota)
        """
        execute(sql, (data["avaliacao_id"], data["matricula_id"], data["nota"]))
        # Retorna o registro atualizado
        row = query("SELECT * FROM notas WHERE avaliacao_id=%s AND matricula_id=%s",
                    (data["avaliacao_id"], data["matricula_id"]))
        return row[0], 201
    except Exception as e:
        return {"erro": str(e)}, 400

@app.get("/notas")
def list_notas():
    matricula_id = request.args.get("matricula_id")
    avaliacao_id = request.args.get("avaliacao_id")
    if matricula_id and avaliacao_id:
        return jsonify(query("SELECT * FROM notas WHERE matricula_id=%s AND avaliacao_id=%s",
                             (matricula_id, avaliacao_id)))
    elif matricula_id:
        return jsonify(query("SELECT * FROM notas WHERE matricula_id=%s", (matricula_id,)))
    elif avaliacao_id:
        return jsonify(query("SELECT * FROM notas WHERE avaliacao_id=%s", (avaliacao_id,)))
    return jsonify(query("SELECT * FROM notas ORDER BY id DESC"))

# -----------------------------
# RELATÓRIOS SIMPLES
# -----------------------------
@app.get("/relatorios/turmas/<int:turma_id>/medias")
def medias_da_turma(turma_id):
    """
    Média ponderada por matrícula (aluno) na turma.
    Não depende de VIEW, calcula direto.
    """
    sql = """
    SELECT
      m.id AS matricula_id,
      a.id AS aluno_id,
      a.nome AS aluno_nome,
      ROUND(
        CASE WHEN SUM(av.peso_percent)=0 THEN NULL
             ELSE SUM(COALESCE(n.nota,0)*av.peso_percent)/SUM(av.peso_percent)
        END, 2
      ) AS media_final
    FROM matriculas m
    JOIN alunos a ON a.id=m.aluno_id
    JOIN avaliacoes av ON av.turma_id=m.turma_id
    LEFT JOIN notas n ON n.avaliacao_id=av.id AND n.matricula_id=m.id
    WHERE m.turma_id=%s
    GROUP BY m.id, a.id, a.nome
    ORDER BY a.nome;
    """
    rows = query(sql, (turma_id,))
    return jsonify(rows)

@app.get("/relatorios/alunos/<int:aluno_id>/boletim")
def boletim_do_aluno(aluno_id):
    """
    Boletim por aluno: disciplina, ano/semestre, média e situação.
    """
    sql = """
    SELECT
      d.codigo AS disciplina_codigo,
      d.nome   AS disciplina_nome,
      t.ano, t.semestre,
      ROUND(
        CASE WHEN SUM(av.peso_percent)=0 THEN NULL
             ELSE SUM(COALESCE(n.nota,0)*av.peso_percent)/SUM(av.peso_percent)
        END, 2
      ) AS media_final,
      CASE
        WHEN SUM(av.peso_percent)=0 THEN 'EM ANDAMENTO'
        WHEN (SUM(COALESCE(n.nota,0)*av.peso_percent)/SUM(av.peso_percent)) >= 6.0 THEN 'APROVADO'
        ELSE 'REPROVADO'
      END AS situacao
    FROM matriculas m
    JOIN turmas t       ON t.id=m.turma_id
    JOIN disciplinas d  ON d.id=t.disciplina_id
    JOIN avaliacoes av  ON av.turma_id=t.id
    LEFT JOIN notas n   ON n.avaliacao_id=av.id AND n.matricula_id=m.id
    WHERE m.aluno_id=%s
    GROUP BY d.codigo, d.nome, t.ano, t.semestre
    ORDER BY t.ano DESC, t.semestre DESC, d.nome;
    """
    rows = query(sql, (aluno_id,))
    return jsonify(rows)

# -----------------------------
# MAIN
# -----------------------------
if __name__ == "__main__":
    # Flask padrão em debug (não use em produção)
    app.run(host="0.0.0.0", port=5000, debug=True)
