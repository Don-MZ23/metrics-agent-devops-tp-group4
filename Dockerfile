# Dockerfile (production)

# ---- Stage 1 : build des dépendances ----
FROM python:3.12-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN grep -v '^pytest' requirements.txt > requirements.prod.txt && \
    pip install --no-cache-dir --prefix=/install -r requirements.prod.txt

# ---- Stage 2 : image finale minimale ----
FROM python:3.12-slim

WORKDIR /app

# procps fournit la commande 'uptime' utilisée par collector.py
RUN apt-get update && \
    apt-get install -y --no-install-recommends procps && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /usr/local
COPY app/ ./app/

RUN useradd -m -u 1000 appuser
USER appuser

ENV PYTHONUNBUFFERED=1
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app.api:app", "--host", "0.0.0.0", "--port", "8000"]
