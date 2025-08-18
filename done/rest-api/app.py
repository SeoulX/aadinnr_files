from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/api")
def api():
    return jsonify({"message": "Hello from REST API in Docker"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
