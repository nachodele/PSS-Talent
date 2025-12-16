from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/health")
def health():
    return jsonify(status="ok"), 200

@app.route("/version")
def version():
    pr_id = os.environ.get("PR_ID", "local")
    sha = os.environ.get("GIT_SHA", "unknown")
    return jsonify(version=pr_id, sha=sha), 200

if __name__ == "__main__":
    port = int(os.environ.get("PORT", "5000"))
    app.run(host="0.0.0.0", port=port)
