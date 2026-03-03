# 灵犀智充软件（Lingxi Charging MVP）

本仓库当前完成 **M1：项目骨架 + Demo 数据**。

## 目录结构

```text
backend/
  app/
    main.py
    db.py
    schema.sql
  scripts/
    init_db.py
    seed_demo.py
  tests/
frontend/
  src/
SPEC.md
AGENTS.md
```

## 环境要求

- Python 3.10+
- Node.js 18+

---

## 一键启动（从空环境）

### 1) 后端初始化与启动

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python scripts/init_db.py
python scripts/seed_demo.py
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

验证：

- 访问健康检查：`http://127.0.0.1:8000/healthz`
- 查看 demo 数据 API：
  - `GET /api/admin/parking-spots`
  - `GET /api/admin/energy-nodes`
  - `GET /api/admin/robots`

### 2) 前端启动

另开终端：

```bash
cd frontend
cp .env.example .env
npm install
npm run dev -- --host 0.0.0.0 --port 5173
```

验证：

- 打开 `http://127.0.0.1:5173`
- 页面可看到：
  - 10 个停车位
  - 2 个供能节点
  - 2 台机器人

---

## 数据库初始化与 Demo 数据

- 初始化 schema：`python scripts/init_db.py`
- 导入演示数据：`python scripts/seed_demo.py`

演示数据默认包含：

- 用户：admin/user01
- 车位：10 个（网格）
- 供能节点：2 个
- 机器人：2 台

---

## 测试

后端单元测试：

```bash
cd backend
source .venv/bin/activate
pytest
```

---

## 里程碑路线（M1–M4）

- M1（已完成）：项目骨架、schema、demo seed、启动文档
- M2：任务创建 API + 调度规则 + 管理端任务列表
- M3：实时推送（WebSocket）+ 地图可视化与时间线
- M4：告警、历史回放、异常演示与可靠性增强
