FROM python:3.12-slim

WORKDIR /app

# System dependencies + Playwright browser deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgbm1 libxkbcommon0 libgtk-3-0 libnss3 libatk-bridge2.0-0 \
    libdrm2 libxcomposite1 libxdamage1 libxrandr2 libatspi2.0-0 \
    libasound2 libpango-1.0-0 libcairo2 libcups2 libxshmfence1 \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir "setuptools<78" && pip install --no-cache-dir -r requirements.txt

# Install Playwright chromium
RUN playwright install chromium

# Download NLTK data
RUN python -c "import nltk; nltk.download('punkt_tab', quiet=True)"

# Application code
COPY . .

EXPOSE 8000
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
