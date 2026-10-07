FROM python:3.12-slim

RUN groupadd -r orderhub && useradd -r -g orderhub -s /bin/bash orderhub

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN chown -R orderhub:orderhub /app

USER orderhub

ENV PORT=8080
EXPOSE 8080

HEALTHCHECK --interval=5s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

CMD ["python", "app/app.py"]