# M1–M4 实现计划（按 SPEC 模块拆分）

## M1：项目骨架 + Demo 数据

### 范围
- 后端 FastAPI 工程骨架、SQLite 连接层
- 按 SPEC 建表：users / parking_spots / energy_nodes / robots / tasks / task_events / alerts
- Demo seed（>=10 车位、>=2 节点、>=2 机器人）
- 前端 React + Vite 基础页，展示 demo 列表
- README 一键启动步骤（env、DB 初始化、seed、启动）

### 文件清单
- backend/app/main.py
- backend/app/db.py
- backend/app/schema.sql
- backend/scripts/init_db.py
- backend/scripts/seed_demo.py
- backend/tests/test_health.py
- backend/requirements.txt
- backend/.env.example
- frontend/package.json
- frontend/index.html
- frontend/vite.config.js
- frontend/src/main.jsx
- frontend/src/App.jsx
- frontend/src/styles.css
- frontend/.env.example
- README.md

### 验收点
- `GET /healthz` 返回 `{"ok": true}`
- 管理端 demo 页面能看到车位/供能节点/机器人列表
- 初始化脚本可重复执行（不破坏已有数据）

### 运行/测试命令
- 后端：`python scripts/init_db.py && python scripts/seed_demo.py && uvicorn app.main:app --reload`
- 前端：`npm install && npm run dev`
- 测试：`pytest`

---

## M2：任务创建 + 调度规则 + 流程跑通

### 范围
- 新增任务创建 API（输入校验）
- 调度模块（空闲优先 + 距离/电量评分）
- 任务状态机骨架（QUEUED→ASSIGNED→...→DONE）
- 管理端任务列表与状态标签

### 文件清单（规划）
- backend/app/api/tasks.py
- backend/app/services/scheduler.py
- backend/app/services/task_runner.py
- backend/app/schemas/task.py
- backend/tests/test_scheduler.py
- backend/tests/test_task_flow.py
- frontend/src/pages/admin/TasksPanel.jsx

### 验收点
- 创建任务后可自动分配机器人
- 状态可模拟推进至 DONE
- 任务列表显示状态与进度

### 运行/测试命令
- `pytest -k "scheduler or task_flow"`
- `curl -X POST /api/tasks` + `GET /api/admin/tasks`

---

## M3：实时推送 + 地图可视化

### 范围
- WebSocket 推送 task/robot/alert 事件
- 管理端 2D 地图画布（车位、节点、机器人、轨迹）
- 任务时间线实时刷新

### 文件清单（规划）
- backend/app/ws/hub.py
- backend/app/services/simulator.py
- frontend/src/pages/admin/Dashboard.jsx
- frontend/src/components/MapCanvas.jsx
- frontend/src/components/TaskTimeline.jsx

### 验收点
- 页面可实时看到机器人移动与状态变更
- 时间线持续写入并展示

### 运行/测试命令
- `uvicorn app.main:app --reload`
- `npm run dev`
- WebSocket smoke：连接 `/ws` 收到 `task.update`/`robot.update`

---

## M4：告警 + 历史回放 + 可靠性

### 范围
- 异常注入：robot offline / docking fail / timeout（至少两类）
- 告警面板、任务失败原因展示
- 历史查询与状态回放（按时间序列）
- 日志增强（包含 task_id/robot_id）

### 文件清单（规划）
- backend/app/api/admin_sim.py
- backend/app/services/alerts.py
- backend/app/services/replay.py
- backend/tests/test_alerts.py
- backend/tests/test_replay.py
- frontend/src/pages/admin/AlertsPanel.jsx
- frontend/src/pages/admin/ReplayPanel.jsx

### 验收点
- 手动触发异常时，任务转 FAILED 并生成 alert
- 可选择历史任务进行事件回放

### 运行/测试命令
- `pytest`
- `POST /api/admin/sim/set-robot-offline/{id}`
- 前端回放操作 smoke test
