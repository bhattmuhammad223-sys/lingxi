import { useEffect, useState } from 'react'

const API = import.meta.env.VITE_API_BASE || 'http://127.0.0.1:8000'

export function App() {
  const [spots, setSpots] = useState([])
  const [nodes, setNodes] = useState([])
  const [robots, setRobots] = useState([])

  useEffect(() => {
    Promise.all([
      fetch(`${API}/api/admin/parking-spots`).then((r) => r.json()),
      fetch(`${API}/api/admin/energy-nodes`).then((r) => r.json()),
      fetch(`${API}/api/admin/robots`).then((r) => r.json()),
    ]).then(([spotsData, nodesData, robotsData]) => {
      setSpots(spotsData)
      setNodes(nodesData)
      setRobots(robotsData)
    })
  }, [])

  return (
    <main>
      <h1>灵犀智充 MVP（M1）</h1>
      <p>当前展示 demo 车位、供能节点与机器人清单。</p>
      <section>
        <h2>停车位 ({spots.length})</h2>
        <ul>{spots.map((s) => <li key={s.id}>{s.code} ({s.x}, {s.y})</li>)}</ul>
      </section>
      <section>
        <h2>供能节点 ({nodes.length})</h2>
        <ul>{nodes.map((n) => <li key={n.id}>{n.name} - {n.status}</li>)}</ul>
      </section>
      <section>
        <h2>机器人 ({robots.length})</h2>
        <ul>{robots.map((r) => <li key={r.id}>{r.name} - {r.status} - 电量 {r.battery}%</li>)}</ul>
      </section>
    </main>
  )
}
