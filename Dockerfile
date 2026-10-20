FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim

ARG LAB_LOGIN
ARG LAB_TOKEN
LABEL org.lab.login=$LAB_LOGIN
LABEL org.lab.token=$LAB_TOKEN

COPY --from=builder /install /usr/local

RUN useradd -m -u 1000 appuser

WORKDIR /app
COPY app/ /app/
RUN chown -R appuser:appuser /app

USER appuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:8000/health').status==200 else 1)"

EXPOSE 8000

ENV TMPDIR=/dev/shm
CMD ["gunicorn", "-b", "0.0.0.0:8000", "app:app"]