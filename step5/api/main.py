#!/usr/bin/env python

import os
import json
import redis

from flask import Flask, request
from linkextractor import extract_links

app = Flask(__name__)

# Configuração do cache
CACHE_ENABLED = os.getenv(
    "CACHE_ENABLED", "true"
).lower() == "true"

# Conexão com Redis
redis_conn = redis.from_url(
    os.getenv("REDIS_URL", "redis://localhost:6379")
)


@app.route("/")
def index():
    return "Usage: http://<hostname>[:<prt>]/api/<url>"


@app.route("/api/<path:url>")
def api(url):

    qs = request.query_string.decode("utf-8")

    if qs != "":
        url += "?" + qs

    jsonlinks = None

    if CACHE_ENABLED:

        # Busca o resultado no Redis
        jsonlinks = redis_conn.get(url)

        if not jsonlinks:
            # Cache MISS: extrai e armazena
            links = extract_links(url)
            jsonlinks = json.dumps(links, indent=2)
            redis_conn.set(url, jsonlinks)

    else:
        # Cache desabilitado: extrai sempre
        links = extract_links(url)
        jsonlinks = json.dumps(links, indent=2)

    response = app.response_class(
        status=200,
        mimetype="application/json",
        response=jsonlinks
    )

    return response


app.run(host="0.0.0.0")
