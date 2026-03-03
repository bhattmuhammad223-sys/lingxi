import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.db import get_conn


def seed_demo() -> None:
    with get_conn() as conn:
        conn.execute("INSERT OR IGNORE INTO users (username, password_hash, role) VALUES ('admin','demo','admin')")
        conn.execute("INSERT OR IGNORE INTO users (username, password_hash, role) VALUES ('user01','demo','user')")

        spots = []
        for idx in range(10):
            row = idx // 5
            col = idx % 5
            spots.append((f'A-{idx+1:03d}', col * 10.0, row * 12.0, 0))
        conn.executemany(
            'INSERT OR IGNORE INTO parking_spots (code, x, y, is_occupied) VALUES (?, ?, ?, ?)',
            spots,
        )

        conn.executemany(
            'INSERT OR IGNORE INTO energy_nodes (name, x, y, status) VALUES (?, ?, ?, ?)',
            [
                ('Node-1', -5.0, 0.0, 'ONLINE'),
                ('Node-2', 55.0, 12.0, 'ONLINE'),
            ],
        )

        conn.executemany(
            'INSERT OR IGNORE INTO robots (name, x, y, status, battery) VALUES (?, ?, ?, ?, ?)',
            [
                ('Robot-01', 0.0, -4.0, 'IDLE', 88),
                ('Robot-02', 48.0, 18.0, 'IDLE', 73),
            ],
        )

        conn.commit()

    print('Seeded demo data: 10 parking spots, 2 energy nodes, 2 robots.')


if __name__ == '__main__':
    seed_demo()
