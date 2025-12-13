# Image stable et légère
FROM python:3.12-alpine

# Variables d'environnement
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Dépendances système
RUN apk add --no-cache bash gcc musl-dev libffi-dev

# ⚠️ UTILISER pip DU VENV (PAS pip3)
RUN /opt/venv/bin/pip install --no-cache-dir -r /tmp/requirements.txt

# Créer un virtualenv (PEP 668 compliant)
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Installer les dépendances Python
COPY ./webapp/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Copier l’application
COPY ./webapp /opt/webapp
WORKDIR /opt/webapp

# Créer utilisateur non-root
RUN adduser -D myuser
USER myuser

# Commande de lancement (Heroku compatible)
CMD gunicorn --bind 0.0.0.0:${PORT:-5000} wsgi:app
