import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.db import DB_PATH, ensure_db_dir, get_conn


def init_db() -> None:
    ensure_db_dir()
    schema_path = ROOT / 'app' / 'schema.sql'
    schema_sql = schema_path.read_text(encoding='utf-8')
    with get_conn() as conn:
        conn.executescript(schema_sql)
        conn.commit()
    print(f'Initialized database at {DB_PATH}')


if __name__ == '__main__':
    init_db()
