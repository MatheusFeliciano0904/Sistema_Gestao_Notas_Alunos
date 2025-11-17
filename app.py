from flask import Flask, request, jsonify, render_template, redirect, url_for
from db import query, execute
import hashlib


app = Flask(__name__, template_folder="templates")

def need(data, fields):
    miss = [f for f in fields if f not in data or data[f] in (None, "")]
    return None if not miss else f"faltam: {', '.join(miss)}"

def hash_pwd(plain: str) -> str:
    """Gera um hash simples (SHA-256) da senha em texto puro."""
    return hashlib.sha256(plain.encode("utf-8")).hexdigest()

# --------- PÁGINAS ---------
@app.get("/")
def root():
    return redirect(url_for("ui"))

@app.get("/ui")
def ui():
    return render_template("index.html")

@app.get("/boletim")
def boletim_page():
    return render_template("boletim.html")

@app.get("/health")
def health():
    return jsonify({"status": "ok"}), 200

# ---------- USUÁRIOS ----------
@app.post("/usuarios")
def usuarios_post():
    """
    JSON esperado:
    {
      "nome": "Admin",
      "email": "admin@escola.com",
      "senha": "123456",
      "perfil": "ADMIN"  # ou "ALUNO" ou "PROFESSOR"
    }
    """
    d = request.get_json(silent=True) or {}
    err = need(d, ["nome", "email", "senha", "perfil"])
    if err:
        return {"erro": err}, 400

    try:
        senha_h = hash_pwd(d["senha"])
        lid = execute(
            "INSERT INTO usuarios (nome, email, senha_hash, perfil) VALUES (%s,%s,%s,%s)",
            (d["nome"], d["email"], senha_h, d["perfil"]),
            True
        )
        # não retornar a senha_hash
        user = query("SELECT id, nome, email, perfil, ativo FROM usuarios WHERE id=%s", (lid,))[0]
        return user, 201
    except Exception as e:
        return {"erro": str(e)}, 400

@app.get("/usuarios")
def usuarios_get():
    users = query("SELECT id, nome, email, perfil, ativo FROM usuarios ORDER BY id")
    return jsonify(users)


# ---------- ALUNOS ----------
@app.post("/alunos")
def alunos_post():
    d = request.get_json(silent=True) or {}
    err = need(d, ["nome", "matricula"])
    if err: return {"erro": err}, 400
    try:
        lid = execute(
            "INSERT INTO alunos (nome, matricula, usuario_id) VALUES (%s,%s,%s)",
            (d["nome"], d["matricula"], d.get("usuario_id")),
            True
        )
        return query("SELECT * FROM alunos WHERE id=%s", (lid,))[0], 201
    except Exception as e:
        return {"erro": str(e)}, 400

@app.get("/alunos")
def alunos_get():
    return jsonify(query("SELECT * FROM alunos ORDER BY id DESC"))


# ---------- DELETE ALUNO ----------
@app.delete("/alunos/<int:aluno_id>")
def alunos_delete(aluno_id):
    """
    Exclui um aluno pelo ID.
    Se o aluno estiver matriculado, o banco impedirá (FK).
    """
    try:
        afetados = execute("DELETE FROM alunos WHERE id=%s", (aluno_id,))
        if afetados == 0:
            return {"erro": "Aluno não encontrado"}, 404
        return {"ok": True, "mensagem": f"Aluno {aluno_id} removido com sucesso"}
    except Exception as e:
        return {"erro": str(e)}, 400


# ---------- Login ----------

@app.post("/login")
def login():
    """
    JSON esperado:
    {
      "email": "admin@escola.com",
      "senha": "123456"
    }
    """
    d = request.get_json(silent=True) or {}
    err = need(d, ["email", "senha"])
    if err:
        return {"erro": err}, 400

    rows = query(
        "SELECT id, nome, email, senha_hash, perfil, ativo FROM usuarios WHERE email=%s",
        (d["email"],)
    )
    if not rows:
        return {"erro": "Usuário não encontrado"}, 404

    u = rows[0]
    if u["ativo"] != 1:
        return {"erro": "Usuário inativo"}, 403

    if u["senha_hash"] != hash_pwd(d["senha"]):
        return {"erro": "Credenciais inválidas"}, 401

    # Login ok – retorno simples, sem token (para fins didáticos)
    return {
        "ok": True,
        "usuario": {
            "id": u["id"],
            "nome": u["nome"],
            "email": u["email"],
            "perfil": u["perfil"]
        }
    }, 200


# ---------- DISCIPLINAS ----------
@app.post("/disciplinas")
def disciplinas_post():
    d = request.get_json(silent=True) or {}
    err = need(d, ["codigo", "nome"])
    if err: return {"erro": err}, 400
    try:
        lid = execute(
            "INSERT INTO disciplinas (codigo, nome) VALUES (%s,%s)",
            (d["codigo"], d["nome"]),
            True
        )
        return query("SELECT * FROM disciplinas WHERE id=%s", (lid,))[0], 201
    except Exception as e:
        return {"erro": str(e)}, 400

@app.get("/disciplinas")
def disciplinas_get():
    return jsonify(query("SELECT * FROM disciplinas ORDER BY id DESC"))

# ---------- TURMAS ----------
@app.post("/turmas")
def turmas_post():
    d = request.get_json(silent=True) or {}
    err = need(d, ["disciplina_id", "ano", "semestre"])
    if err: return {"erro": err}, 400
    try:
        lid = execute(
            """INSERT INTO turmas (disciplina_id, professor_id, ano, semestre)
               VALUES (%s,%s,%s,%s)""",
            (d["disciplina_id"], d.get("professor_id"), d["ano"], d["semestre"]),
            True
        )
        return query(
            """SELECT t.*, d.codigo disciplina_codigo, d.nome disciplina_nome
               FROM turmas t JOIN disciplinas d ON d.id=t.disciplina_id
               WHERE t.id=%s""",
            (lid,)
        )[0], 201
    except Exception as e:
        return {"erro": str(e)}, 400

@app.get("/turmas")
def turmas_get():
    return jsonify(query(
        """SELECT t.*, d.codigo disciplina_codigo, d.nome disciplina_nome
           FROM turmas t JOIN disciplinas d ON d.id=t.disciplina_id
           ORDER BY t.id DESC"""
    ))

# ---------- MATRÍCULAS ----------
@app.post("/matriculas")
def matriculas_post():
    d = request.get_json(silent=True) or {}
    err = need(d, ["turma_id", "aluno_id"])
    if err: return {"erro": err}, 400
    try:
        lid = execute(
            "INSERT INTO matriculas (turma_id, aluno_id) VALUES (%s,%s)",
            (d["turma_id"], d["aluno_id"]),
            True
        )
        return query("SELECT * FROM matriculas WHERE id=%s", (lid,))[0], 201
    except Exception as e:
        return {"erro": str(e)}, 400

@app.get("/matriculas")
def matriculas_get():
    return jsonify(query(
        """SELECT m.*, a.nome aluno_nome, a.matricula aluno_matricula,
                  d.codigo disciplina_codigo, d.nome disciplina_nome, t.ano, t.semestre
           FROM matriculas m
           JOIN alunos a ON a.id=m.aluno_id
           JOIN turmas t ON t.id=m.turma_id
           JOIN disciplinas d ON d.id=t.disciplina_id
           ORDER BY m.id DESC"""
    ))

# ---------- AVALIAÇÕES ----------
@app.post("/avaliacoes")
def avaliacoes_post():
    d = request.get_json(silent=True) or {}
    err = need(d, ["turma_id", "titulo", "peso_percent"])
    if err: return {"erro": err}, 400
    try:
        lid = execute(
            "INSERT INTO avaliacoes (turma_id, titulo, peso_percent) VALUES (%s,%s,%s)",
            (d["turma_id"], d["titulo"], d["peso_percent"]),
            True
        )
        return query("SELECT * FROM avaliacoes WHERE id=%s", (lid,))[0], 201
    except Exception as e:
        return {"erro": str(e)}, 400

@app.get("/avaliacoes")
def avaliacoes_get():
    turma_id = request.args.get("turma_id")
    if turma_id:
        return jsonify(query("SELECT * FROM avaliacoes WHERE turma_id=%s", (turma_id,)))
    return jsonify(query("SELECT * FROM avaliacoes ORDER BY id DESC"))

# ---------- NOTAS (upsert) ----------
@app.post("/notas")
def notas_post():
    d = request.get_json(silent=True) or {}
    err = need(d, ["avaliacao_id", "matricula_id", "nota"])
    if err: return {"erro": err}, 400
    try:
        execute(
            """INSERT INTO notas (avaliacao_id, matricula_id, nota)
               VALUES (%s,%s,%s)
               ON DUPLICATE KEY UPDATE nota=VALUES(nota)""",
            (d["avaliacao_id"], d["matricula_id"], d["nota"])
        )
        return query(
            "SELECT * FROM notas WHERE avaliacao_id=%s AND matricula_id=%s",
            (d["avaliacao_id"], d["matricula_id"])
        )[0], 201
    except Exception as e:
        return {"erro": str(e)}, 400

@app.get("/notas")
def notas_get():
    return jsonify(query("SELECT * FROM notas ORDER BY id DESC"))


# ---------- BOLETIM ----------


@app.get("/relatorios/alunos/<int:aluno_id>/boletim")
def relatorio_boletim_aluno(aluno_id):
    """
    Retorna o boletim do aluno: disciplinas, ano/semestre, média e situação.
    """
    sql = """
    SELECT
      d.codigo AS disciplina_codigo,
      d.nome   AS disciplina_nome,
      t.ano,
      t.semestre,
      ROUND(
        CASE WHEN SUM(av.peso_percent) = 0 THEN NULL
             ELSE SUM(COALESCE(n.nota, 0) * av.peso_percent) / SUM(av.peso_percent)
        END, 2
      ) AS media_final,
      CASE
        WHEN SUM(av.peso_percent) = 0 THEN 'EM ANDAMENTO'
        WHEN (SUM(COALESCE(n.nota, 0) * av.peso_percent) / SUM(av.peso_percent)) >= 6.0
          THEN 'APROVADO'
        ELSE 'REPROVADO'
      END AS situacao
    FROM matriculas m
    JOIN turmas t       ON t.id = m.turma_id
    JOIN disciplinas d  ON d.id = t.disciplina_id
    JOIN avaliacoes av  ON av.turma_id = t.id
    LEFT JOIN notas n   ON n.avaliacao_id = av.id AND n.matricula_id = m.id
    WHERE m.aluno_id = %s
    GROUP BY d.codigo, d.nome, t.ano, t.semestre
    ORDER BY t.ano DESC, t.semestre DESC, d.nome;
    """
    return jsonify(query(sql, (aluno_id,)))





# ---------- RELATÓRIOS ----------
@app.get("/relatorios/turmas/<int:turma_id>/medias")
def relatorio_medias_turma(turma_id):
    """
    Retorna a média final de cada aluno matriculado na turma.
    A média é ponderada pelos pesos das avaliações.
    """
    sql = """
    SELECT
      m.id AS matricula_id,
      a.id AS aluno_id,
      a.nome AS aluno_nome,
      ROUND(
        CASE WHEN SUM(av.peso_percent) = 0 THEN NULL
             ELSE SUM(COALESCE(n.nota, 0) * av.peso_percent) / SUM(av.peso_percent)
        END, 2
      ) AS media_final
    FROM matriculas m
    JOIN alunos a       ON a.id = m.aluno_id
    JOIN avaliacoes av  ON av.turma_id = m.turma_id
    LEFT JOIN notas n   ON n.avaliacao_id = av.id AND n.matricula_id = m.id
    WHERE m.turma_id = %s
    GROUP BY m.id, a.id, a.nome
    ORDER BY a.nome;
    """
    return jsonify(query(sql, (turma_id,)))






if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)


