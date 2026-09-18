FROM python:3.12.5-slim AS builder

WORKDIR /build
COPY app.py .

FROM python:3.12.5-slim

RUN useradd --create-home --uid 10001 appuser
WORKDIR /app
COPY --from=builder --chown=appuser:appuser /build/app.py .

USER 10001
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
EXPOSE 8080
CMD ["python", "app.py"]
