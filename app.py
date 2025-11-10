from flask import Flask, request, jsonify, render_template, redirect, url_for
from db import query, execute

app = Flask(__name__, template_folder="templates")

def need(data, fields):
    miss = [f for f in fields if f not in data or data[f] in (None, "")]
    return None if not miss else f"faltam: {', '.join(miss)}"

# --------- PÁGINAS ---------
@app.get("/")
def root():
    return redirect(url_for("ui"))

@app.get("/ui")
def ui():
    return render_template("index.html")

@app.get("/health")
def health():
    return jsonify({"status": "ok"}), 200

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

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
