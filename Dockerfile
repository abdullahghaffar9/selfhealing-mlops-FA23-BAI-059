FROM python:3.10-slim

WORKDIR /app

# Combine apt updates and cleanup in one layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Install dependencies AND clear pip cache in the same RUN command
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    rm -rf /root/.cache/pip

COPY . .

CMD ["python", "app.py"]
