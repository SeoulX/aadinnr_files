from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from bson import ObjectId  # to handle ObjectId
import os

app = Flask(__name__)
CORS(app)

MONGO_URI = os.getenv("MONGO_URI", "mongodb://db:27017/")
DB_NAME = os.getenv("DB_NAME", "mydatabase")
COLLECTION_NAME = os.getenv("COLLECTION_NAME", "mycollection")
BACKEND_PORT = int(os.getenv("BACKEND_PORT", 5000))

# Connect to MongoDB
client = MongoClient(MONGO_URI)
db = client[DB_NAME]
collection = db[COLLECTION_NAME]

# Helper function to convert ObjectId to string
def serialize_document(doc):
    doc["_id"] = str(doc["_id"])
    return doc

@app.route("/api/data", methods=["GET"])
def get_data():
    data = [serialize_document(d) for d in collection.find()]
    return jsonify(data)

@app.route("/api/data", methods=["POST"])
def add_data():
    new_data = request.json
    result = collection.insert_one(new_data)
    inserted_doc = collection.find_one({"_id": result.inserted_id})
    return jsonify(serialize_document(inserted_doc)), 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
