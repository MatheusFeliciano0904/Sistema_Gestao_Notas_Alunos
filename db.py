import os
from dotenv import load_dotenv
import mysql.connector
from mysql.connector import pooling

load_dotenv()  # carrega variáveis do .env

CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", "3306")),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", "Judo09041003."),
    "database": os.getenv("DB_NAME", "escola_notas"),
    "auth_plugin": os.getenv("DB_AUTH_PLUGIN", "mysql_native_password"),
}

# Pool de conexões simples para evitar reconectar a cada request
POOL = pooling.MySQLConnectionPool(pool_name="pool_notas", pool_size=5, **CONFIG)

def get_conn():
    """Obtem uma conexão do pool."""
    return POOL.get_connection()

def query(sql, params=None, many=False):
    """
    SELECT/consultas.
    Retorna lista de dicionários (cada linha).
    """
    conn = get_conn()
    try:
        cur = conn.cursor(dictionary=True)
        if many and isinstance(params, list):
            cur.executemany(sql, params)
        else:
            cur.execute(sql, params or ())
        rows = cur.fetchall()
        return rows
    finally:
        cur.close()
        conn.close()

def execute(sql, params=None, many=False, return_last_id=False):
    """
    INSERT/UPDATE/DELETE.
    Se return_last_id=True, retorna o lastrowid.
    """
    conn = get_conn()
    try:
        cur = conn.cursor(dictionary=True)
        if many and isinstance(params, list):
            cur.executemany(sql, params)
        else:
            cur.execute(sql, params or ())
        conn.commit()
        return cur.lastrowid if return_last_id else cur.rowcount
    finally:
        cur.close()
        conn.close()
