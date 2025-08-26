// frontend/pages/api/data.js
export default async function handler(req, res) {
  const backendUrl = process.env.BACKEND_URL || "http://localhost:5000";

  try {
    const response = await fetch(`${backendUrl}/api/data`, {
      method: req.method,
      headers: { "Content-Type": "application/json" },
      body: req.method === "POST" ? JSON.stringify(req.body) : undefined,
    });

    const data = await response.json();
    res.status(response.status).json(data);
  } catch (err) {
    res.status(500).json({ error: "Backend not reachable", details: err.message });
  }
}
