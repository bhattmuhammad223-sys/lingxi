from fastapi import FastAPI

from app.db import get_conn

app = FastAPI(title='Lingxi Charging MVP')


@app.get('/healthz')
def healthz():
    return {'ok': True}


@app.get('/api/admin/parking-spots')
def list_parking_spots():
    with get_conn() as conn:
        rows = conn.execute('SELECT id, code, x, y, is_occupied FROM parking_spots ORDER BY id').fetchall()
    return [dict(r) for r in rows]


@app.get('/api/admin/energy-nodes')
def list_energy_nodes():
    with get_conn() as conn:
        rows = conn.execute('SELECT id, name, x, y, status FROM energy_nodes ORDER BY id').fetchall()
    return [dict(r) for r in rows]


@app.get('/api/admin/robots')
def list_robots():
    with get_conn() as conn:
        rows = conn.execute('SELECT id, name, x, y, status, battery FROM robots ORDER BY id').fetchall()
    return [dict(r) for r in rows]
