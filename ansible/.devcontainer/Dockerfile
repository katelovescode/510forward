FROM mcr.microsoft.com/devcontainers/python:3.12

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

COPY collections-requirements.yml /tmp/collections-requirements.yml
RUN ansible-galaxy collection install -r /tmp/collections-requirements.yml