# One-shot seed container: loads sample data into bronze via pyiceberg.
FROM python:3.12-slim

# Pinned so the seed doesn't rot when pyiceberg releases breaking changes.
RUN pip install --no-cache-dir "pyiceberg[s3fs,pyarrow]==0.9.1"

WORKDIR /app
CMD ["python", "/app/seed/load_sample.py"]
