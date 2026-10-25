from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    return "Hello, World! Welcome to Tech Challenge 2."

@app.route("/health")
def health():
    return {"status": "healthy"}, 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)