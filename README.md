# 灵犀智充（MVP）— 本地运行指南

本仓库包含：
- backend：后端 API（FastAPI）+ SQLite 数据库 + demo 数据脚本
- frontend：前端管理台/用户端（React + Vite）

## 1) 环境要求
- Python 3.10+（建议 3.11）
- Node.js 18+（建议 18/20）
- （可选）make

---

## 2) 后端启动（backend）

### 2.1 创建虚拟环境并安装依赖
```bash
cd backend
python -m venv .venv
# macOS/Linux
source .venv/bin/activate
# Windows PowerShell
# .venv\Scripts\Activate.ps1

pip install -r requirements.txt
