FROM python:3.10-slim

WORKDIR /app

# Install build dependencies AND Chromium/Driver
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    chromium \
    chromium-driver \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    rm -rf /root/.cache/pip

COPY . .

# Set environment variables so Selenium can find the browser
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMEDRIVER_PATH=/usr/bin/chromedriver

CMD ["python", "app.py"]
