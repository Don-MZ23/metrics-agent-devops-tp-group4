# Dockerfile (production)

# ---- Stage 1 : build des dépendances ----
FROM python:3.12-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# On exclut pytest en prod : on installe seulement les deps nécessaires à l'exécution
RUN pip install --no-cache-dir --prefix=/install \
    fastapi uvicorn[standard] psutil requests python-dotenv

# ---- Stage 2 : image finale minimale ----
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
WORKDIR /app

# Récupère uniquement les paquets installés, pas les outils de build
COPY --from=builder /install /usr/local

RUN apt-get update && apt-get install -y --no-install-recommends \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash appuser
USER appuser

COPY --chown=appuser:appuser app/ ./app/

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health').raise_for_status()" || exit 1

CMD ["uvicorn", "app.api:app", "--host", "0.0.0.0", "--port", "8000"]
