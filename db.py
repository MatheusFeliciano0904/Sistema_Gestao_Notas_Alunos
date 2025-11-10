import os
from dotenv import load_dotenv
import mysql.connector
from mysql.connector import pooling

load_dotenv()

CFG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 3306)),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", "Judo09041003."),
    "database": os.getenv("DB_NAME", "escola_notas"),
    "auth_plugin": os.getenv("DB_AUTH_PLUGIN", "mysql_native_password"),
}

POOL = pooling.MySQLConnectionPool(pool_name="pool_notas", pool_size=5, **CFG)

def _conn():
    return POOL.get_connection()

def query(sql, params=None):
    c = _conn(); cur = c.cursor(dictionary=True)
    try:
        cur.execute(sql, params or ())
        return cur.fetchall()
    finally:
        cur.close(); c.close()

def execute(sql, params=None, return_last_id=False):
    c = _conn(); cur = c.cursor()
    try:
        cur.execute(sql, params or ())
        c.commit()
        return cur.lastrowid if return_last_id else cur.rowcount
    finally:
        cur.close(); c.close()
