import os
import time
from collections import defaultdict, deque

import requests
from flask import Flask, request, jsonify

app = Flask(__name__)

ALLOWED_ORIGINS = {"https://snehabogaram75-hub.github.io"}


@app.after_request
def add_cors(resp):
    origin = request.headers.get("Origin", "")
    if origin in ALLOWED_ORIGINS:
        resp.headers["Access-Control-Allow-Origin"] = origin
        resp.headers["Access-Control-Allow-Headers"] = "Content-Type, X-App-Token"
        resp.headers["Access-Control-Allow-Methods"] = "POST, OPTIONS"
        resp.headers["Vary"] = "Origin"
    return resp

GROQ_KEY = os.environ.get("GROQ_API_KEY", "")
MODEL = os.environ.get("GROQ_MODEL", "openai/gpt-oss-20b")
APP_TOKEN = os.environ.get("APP_TOKEN", "")

SYSTEM = (
    "You draft short, polite, factual complaint letters for an Indian "
    "auto-rickshaw passenger. Use ONLY the facts provided. Never invent "
    "names, dates, laws or amounts; if a fact is missing, leave it out. "
    "Address it to 'The Concerned Officer, Regional Transport Office'. "
    "Include the auto registration number, trip distance, app estimate, "
    "fare demanded and the app's verdict. State that the estimate comes "
    "from the AutoFareFixer app and is indicative only. Politely request "
    "a review. Maximum 150 words. Plain text, no markdown."
)


PER_IP_LIMIT = int(os.environ.get("PER_IP_LIMIT", "10"))
GLOBAL_LIMIT = int(os.environ.get("GLOBAL_LIMIT", "300"))
IP_HITS = defaultdict(deque)
GLOBAL_HITS = deque()


def allowed(ip):
    now = time.time()
    q = IP_HITS[ip]
    while q and now - q[0] > 3600:
        q.popleft()
    while GLOBAL_HITS and now - GLOBAL_HITS[0] > 86400:
        GLOBAL_HITS.popleft()
    if len(q) >= PER_IP_LIMIT or len(GLOBAL_HITS) >= GLOBAL_LIMIT:
        return False
    q.append(now)
    GLOBAL_HITS.append(now)
    return True


def clean(value, limit=300):
    return str(value if value is not None else "").strip()[:limit]


@app.get("/health")
def health():
    return jsonify(ok=True)


@app.post("/complaint-letter")
def complaint_letter():
    if APP_TOKEN and request.headers.get("X-App-Token") != APP_TOKEN:
        return jsonify(error="unauthorized"), 401
    fwd = request.headers.get("X-Forwarded-For", request.remote_addr or "")
    if not allowed(fwd.split(",")[0].strip()):
        return jsonify(error="rate limited"), 429
    if not GROQ_KEY:
        return jsonify(error="server not configured"), 500

    data = request.get_json(silent=True) or {}
    facts = {
        "Auto registration": clean(data.get("plate"), 20),
        "Distance (km)": clean(data.get("distance"), 10),
        "App estimate (INR)": clean(data.get("fare"), 10),
        "Fare demanded (INR)": clean(data.get("demanded"), 10),
        "App verdict": clean(data.get("verdict"), 30),
        "Passenger notes": clean(data.get("notes"), 300),
        "Time": clean(data.get("time"), 30),
    }
    facts_text = "\n".join(f"{k}: {v}" for k, v in facts.items() if v)

    try:
        r = requests.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={"Authorization": f"Bearer {GROQ_KEY}"},
            json={
                "model": MODEL,
                "temperature": 0.3,
                "max_tokens": 1500,
                "messages": [
                    {"role": "system", "content": SYSTEM},
                    {"role": "user", "content": facts_text},
                ],
            },
            timeout=30,
        )
    except requests.RequestException:
        return jsonify(error="llm unreachable"), 502

    if r.status_code != 200:
        return jsonify(error="llm error", status=r.status_code), 502

    text = (r.json()["choices"][0]["message"].get("content") or "").strip()
    if not text:
        return jsonify(error="empty response"), 502
    return jsonify(letter=text)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
