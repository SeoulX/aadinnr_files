import time
import pymysql
from flask import Flask
import os

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST", "db")
DB_USER = os.environ.get("DB_USER", "root")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "rootpass")
DB_NAME = os.environ.get("DB_NAME", "mydatabase")

def get_connection():
    retries = 5
    while retries > 0:
        try:
            return pymysql.connect(
                host=DB_HOST,
                user=DB_USER,
                password=DB_PASSWORD,
                database=DB_NAME,
                cursorclass=pymysql.cursors.DictCursor
            )
        except Exception as e:
            print(f"DB not ready, retrying... ({e})")
            retries -= 1
            time.sleep(3)
    raise Exception("Could not connect to DB after retries")

@app.route("/")
def index():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("CREATE TABLE IF NOT EXISTS users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100))")
        cursor.execute("INSERT INTO users (name) VALUES ('Andrian')")
        conn.commit()
        cursor.execute("SELECT * FROM users")
        rows = cursor.fetchall()
        conn.close()
        return f"<h1>✅ Database Connected!</h1>{rows}"
    except Exception as e:
        return f"❌ Database Connection Failed: {e}"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
