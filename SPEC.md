# SPEC.md — 灵犀智充软件（MVP）规格说明

## 1. 产品范围（MVP）
目标：交付一个可演示闭环的软件系统（用户提交充电任务 → 调度分配机器人 → 执行状态推进 → 实时可视化 → 完成/异常 → 历史回放）。

### 角色
- 车主（User）：提交充电任务、查看自己任务进度
- 管理员（Admin）：地图监控、设备管理、任务管理、告警、历史回放

---

## 2. 核心概念与数据模型（Domain Model）

### 实体
- ParkingLot：停车场（可选，MVP 也可以只做一个停车场）
- ParkingSpot：车位（带坐标）
- EnergyNode：供能/补能节点（带坐标）
- Robot：移动充电机器人（带坐标、状态、电量等）
- Task：充电任务（目标车位、需求、电量目标、优先级、状态）
- TaskEvent：任务事件（用于时间线与回放）
- Alert：告警（设备离线、任务超时、对接失败等）
- User：用户（至少区分 admin / user）

---

## 3. 状态机（Task & Robot）

### 3.1 Task 状态（推荐枚举）
- `QUEUED`：已创建，等待调度
- `ASSIGNED`：已分配机器人
- `GO_TO_ENERGY_NODE`：前往供能节点
- `DOCKING_ENERGY`：供能节点接驳中
- `GO_TO_SPOT`：前往目标车位
- `ALIGNING`：对位/对接准备
- `CHARGING`：充电中
- `RETURNING`：回收/返回待命点（或回到供能节点）
- `DONE`：完成
- `FAILED`：失败（原因写入 task.fail_reason）
- `CANCELLED`：取消（可选，MVP 可不做）

### 3.2 Robot 状态（推荐枚举）
- `IDLE`：空闲
- `BUSY`：执行任务中
- `OFFLINE`：离线
- `FAULT`：故障
- `CHARGING_SELF`：自充/补能（可选）

### 3.3 推进规则（MVP 可模拟）
- 任务创建：`QUEUED`
- 调度成功：`ASSIGNED`，robot -> `BUSY`
- 状态推进：按固定时间步进（例如每 2 秒推进一小步），同时更新 robot 位置（插值移动）
- 充电阶段：模拟电量/充电进度（0→100%）
- 异常：随机或手动触发（robot offline / 超时 / docking fail），task -> `FAILED` 并生成 alert

> 要求：每次状态变化必须写入 `TaskEvent`，用于 UI 时间线与历史回放。

---

## 4. 数据库 Schema（SQLite / 可迁移）

> 字段命名示例，实际可按 ORM 习惯调整；MVP 优先可用性。

### 4.1 users
- id (pk)
- username (unique)
- password_hash
- role (`admin` / `user`)
- created_at

### 4.2 parking_spots
- id (pk)
- code (如 A-001)
- x, y (float) — 2D 坐标
- is_occupied (bool) — 可选
- created_at

### 4.3 energy_nodes
- id (pk)
- name
- x, y
- status (`ONLINE`/`OFFLINE`/`FAULT`)
- created_at

### 4.4 robots
- id (pk)
- name
- x, y
- status (`IDLE`/`BUSY`/`OFFLINE`/`FAULT`)
- battery (0-100)
- current_task_id (nullable)
- last_heartbeat_at (nullable)
- created_at

### 4.5 tasks
- id (pk)
- user_id (fk users.id)
- parking_spot_id (fk parking_spots.id)
- assigned_robot_id (fk robots.id, nullable)
- energy_node_id (fk energy_nodes.id, nullable)
- priority (int default 0)
- target_kwh (float nullable) 或 target_percent (int nullable)
- status (task state enum)
- progress (0-100)
- fail_reason (text nullable)
- created_at, updated_at
- started_at, finished_at (nullable)

### 4.6 task_events
- id (pk)
- task_id (fk tasks.id)
- ts (datetime)
- type (text) 例如 `STATE_CHANGE` / `POSITION_UPDATE` / `ERROR`
- message (text)
- payload_json (text) — 存 robot位置/进度/状态等快照（用于回放）

### 4.7 alerts
- id (pk)
- ts
- level (`INFO`/`WARN`/`ERROR`)
- category (`ROBOT`/`TASK`/`ENERGY_NODE`)
- ref_id (nullable) — 对应 robot_id/task_id/node_id
- message
- is_ack (bool default false)

---

## 5. API 设计（REST + 实时推送）

### 5.1 Auth（MVP 可简化）
- `POST /api/auth/login` → {token}
- `GET /api/auth/me`

> MVP 可用简单 JWT 或 session；如果比赛不强调安全，可先做“演示登录”但要区分 admin/user。

### 5.2 用户端
- `POST /api/tasks`
  - body: { parking_spot_id, target_percent?, target_kwh?, priority? }
  - resp: { task_id, status }
- `GET /api/tasks/my` → 列表
- `GET /api/tasks/{task_id}` → 详情（含 progress、assigned robot、events 简要）

### 5.3 管理端（Admin）
- `GET /api/admin/robots`
- `POST /api/admin/robots` / `PUT /api/admin/robots/{id}`
- `GET /api/admin/energy-nodes`
- `GET /api/admin/parking-spots`
- `GET /api/admin/tasks?status=&q=&from=&to=`
- `GET /api/admin/tasks/{task_id}`（含完整 event 时间线）
- `POST /api/admin/tasks/{task_id}/cancel`（可选）
- `POST /api/admin/sim/trigger-alert`（用于演示触发异常）
- `POST /api/admin/sim/set-robot-offline/{robot_id}`（用于演示离线）

### 5.4 调度 / 执行（后端内部可暴露少量接口）
- `POST /api/admin/sim/step`（可选：手动推进一次）
- `POST /api/admin/sim/run?on=true`（可选：开启/关闭自动推进）

### 5.5 实时推送（WebSocket 推荐）
- `WS /ws`
  - 服务器推送事件：
    - `robot.update`：{robot}
    - `task.update`：{task}
    - `task.event`：{task_id, event}
    - `alert.new`：{alert}
  - 客户端订阅（可选）：
    - `subscribe`: {type:"task", task_id} 或 {type:"admin"}

> MVP 简化：admin 页面连接后直接推全量更新（频率控制，例如 1s/2s）。

---

## 6. 调度算法（MVP 规则法）
### 输入
- 新任务（QUEUED）
- robots 列表（IDLE 且 ONLINE）
- 距离估计：使用欧氏距离（robot位置→目标车位 或 robot→供能节点→车位）

### 输出
- 选中 robot_id + energy_node_id（可选：就近节点）
### 规则（建议）
1. 过滤：robot.status == IDLE 且非 OFFLINE/FAULT
2. 评分：score = w1 * dist(robot, spot) + w2 * (100 - battery) + w3 * queue_penalty
3. 选最小 score
4. 分配后更新：task.assigned_robot_id、robot.current_task_id、task.status=ASSIGNED

---

## 7. 前端页面结构（React）
### 用户端
- `/`：提交任务（选择车位 + 需求）
- `/my-tasks`：我的任务列表
- `/my-tasks/:id`：任务详情（进度条 + 简要时间线）

### 管理端
- `/admin/login`
- `/admin/dashboard`
  - 左侧：任务列表（筛选状态）
  - 中间：地图画布（车位/供能节点/机器人点位+轨迹）
  - 右侧：选中任务详情（状态、进度、robot、event 时间线）
- `/admin/devices`：机器人/供能节点/车位管理（MVP 可合并到 dashboard）
- `/admin/alerts`：告警列表（可在 dashboard 下方做抽屉）

---

## 8. Demo 数据（必须提供）
- 车位：≥ 10 个，呈网格分布（方便地图展示）
- 供能节点：≥ 2 个
- 机器人：≥ 2 台，初始位置不同、电量不同
- 初始任务：0 条（演示从创建开始），可另提供 “seed tasks” 便于回放展示

提供脚本：
- `python scripts/init_db.py`
- `python scripts/seed_demo.py`

---

## 9. 验收用例（必须能演示）
1) 管理员打开 dashboard：能看到地图上车位/节点/机器人
2) 用户提交任务：任务进入 QUEUED，随后变 ASSIGNED
3) 任务实时推进：地图上机器人移动 + 状态依次变化直到 DONE
4) 异常演示：一键触发 robot offline → 任务 FAILED + 生成 alert
5) 历史回放：打开任务详情，能回放事件序列（时间线/播放）

---

## 10. 测试要求（最低限度）
- 单元测试：
  - 调度选择（输入 robots/tasks → 输出选中 robot）
  - 状态机推进（若干 step 后状态序列正确）
- 集成测试（至少 1 条）：
  - 创建任务 → 后端分配 → 查询任务详情状态变化（可用 mock 时间或手动 step）

---

## 11. 非功能要求（MVP 约束）
- 启动命令固定且写入 README（前后端分别一条）
- 日志包含：task_id、robot_id、状态变化
- 频率控制：推送/位置更新不要太快（1~2 秒即可，比赛展示更稳）
