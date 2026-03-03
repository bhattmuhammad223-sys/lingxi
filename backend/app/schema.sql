PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('admin', 'user')),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS parking_spots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT NOT NULL UNIQUE,
    x REAL NOT NULL,
    y REAL NOT NULL,
    is_occupied INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS energy_nodes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    x REAL NOT NULL,
    y REAL NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('ONLINE', 'OFFLINE', 'FAULT')),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS robots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    x REAL NOT NULL,
    y REAL NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('IDLE', 'BUSY', 'OFFLINE', 'FAULT')),
    battery INTEGER NOT NULL CHECK(battery >= 0 AND battery <= 100),
    current_task_id INTEGER,
    last_heartbeat_at TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(current_task_id) REFERENCES tasks(id)
);

CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    parking_spot_id INTEGER NOT NULL,
    assigned_robot_id INTEGER,
    energy_node_id INTEGER,
    priority INTEGER NOT NULL DEFAULT 0,
    target_kwh REAL,
    target_percent INTEGER,
    status TEXT NOT NULL CHECK(status IN (
        'QUEUED','ASSIGNED','GO_TO_ENERGY_NODE','DOCKING_ENERGY','GO_TO_SPOT','ALIGNING','CHARGING','RETURNING','DONE','FAILED','CANCELLED'
    )),
    progress INTEGER NOT NULL DEFAULT 0,
    fail_reason TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at TEXT,
    finished_at TEXT,
    FOREIGN KEY(user_id) REFERENCES users(id),
    FOREIGN KEY(parking_spot_id) REFERENCES parking_spots(id),
    FOREIGN KEY(assigned_robot_id) REFERENCES robots(id),
    FOREIGN KEY(energy_node_id) REFERENCES energy_nodes(id)
);

CREATE TABLE IF NOT EXISTS task_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER NOT NULL,
    ts TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    type TEXT NOT NULL,
    message TEXT NOT NULL,
    payload_json TEXT,
    FOREIGN KEY(task_id) REFERENCES tasks(id)
);

CREATE TABLE IF NOT EXISTS alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ts TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    level TEXT NOT NULL CHECK(level IN ('INFO', 'WARN', 'ERROR')),
    category TEXT NOT NULL CHECK(category IN ('ROBOT', 'TASK', 'ENERGY_NODE')),
    ref_id INTEGER,
    message TEXT NOT NULL,
    is_ack INTEGER NOT NULL DEFAULT 0
);
