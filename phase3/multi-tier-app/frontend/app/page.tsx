"use client";

import { useEffect, useState } from "react";

type DataItem = {
  name: string;
  surname: string;
};

export default function Home() {
  const [data, setData] = useState<DataItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || "";

  // Form state
  const [name, setName] = useState("");
  const [surname, setSurname] = useState("");

  // Fetch data from Flask backend
  const fetchData = async () => {
    try {
      setLoading(true);
      const res = await fetch(`${backendUrl}/api/data`);
      if (!res.ok) throw new Error("Failed to fetch data");
      const result = await res.json();
      setData(result);
    } catch (err: any) {
      setError(err.message || "Something went wrong");
    } finally {
      setLoading(false);
    }
  };

  // Add new data
  const addData = async () => {
    if (!name || !surname) {
      setError("Please enter both name and surname");
      return;
    }

    try {
      await fetch(`${backendUrl}/api/data`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, surname }),
      });
      setName("");
      setSurname("");
      fetchData(); // Refresh after adding
    } catch (err: any) {
      setError(err.message || "Failed to add data");
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  return (
    <div style={{ padding: 20 }}>
      <h1>3-Tier App (Next.js + Flask + MongoDB)</h1>
      
      <div style={{ marginBottom: 10 }}>
        <input
          type="text"
          placeholder="Enter Name"
          value={name}
          onChange={(e) => setName(e.target.value)}
          style={{ marginRight: 5, padding: 5 }}
        />
        <input
          type="text"
          placeholder="Enter Surname"
          value={surname}
          onChange={(e) => setSurname(e.target.value)}
          style={{ marginRight: 5, padding: 5 }}
        />
        <button onClick={addData}>Add Data</button>
      </div>

      {loading && <p>Loading...</p>}
      {error && <p style={{ color: "red" }}>{error}</p>}

      <ul>
        {data.map((item, i) => (
          <li key={i}>
            {item.name} {item.surname}
          </li>
        ))}
      </ul>
    </div>
  );
}
