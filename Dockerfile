FROM python:3.12-alpine

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Dépendances système (souvent nécessaires)
RUN apk add --no-cache gcc musl-dev libffi-dev bash

# Créer le virtualenv
RUN python -m venv /opt/venv

# Forcer l'utilisation du venv
ENV PATH="/opt/venv/bin:$PATH"

# Copier les dépendances
COPY webapp/requirements.txt /tmp/requirements.txt

# ⚠️ UTILISER pip DU VENV (PAS pip3)
RUN /opt/venv/bin/pip install --no-cache-dir -r /tmp/requirements.txt

# Copier l'application
COPY webapp /opt/webapp
WORKDIR /opt/webapp

# Sécurité : utilisateur non-root
RUN adduser -D myuser
USER myuser

# Lancement
CMD gunicorn --bind 0.0.0.0:${PORT:-5000} wsgi:app
