import os
from flask import Flask, jsonify

app = Flask(__name__)

APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
BUILD_NUMBER = os.getenv("BUILD_NUMBER", "unknown")
GIT_COMMIT = os.getenv("GIT_COMMIT", "unknown")

@app.route('/', methods=['GET'])
def index():
    return "OrderHub API", 200

@app.route('/health', methods=['GET'])
def health():
    return jsonify(status="UP"), 200

@app.route('/orders', methods=['GET'])
def get_orders():
    return jsonify([
        {"id": 101, "item": "Laptop", "amount": 1200},
        {"id": 102, "item": "Mouse", "amount": 25}
    ]), 200

@app.route('/version', methods=['GET'])
def get_version():
    return jsonify({
        "version": APP_VERSION,
        "build": BUILD_NUMBER,
        "commit": GIT_COMMIT
    }), 200

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8080))
    # Correct binding to 0.0.0.0 so container accepts external host traffic
    app.run(host="0.0.0.0", port=port)