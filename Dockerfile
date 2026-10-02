FROM python:3.12-slim

WORKDIR /app

# Create non-root user early so it can own /app (and the .venv inside it)
RUN useradd --create-home appuser && chown appuser:appuser /app

# Install uv (fast Python package manager)
RUN pip install --no-cache-dir uv

# Copy dependency files first (Docker layer caching)
COPY --chown=appuser:appuser pyproject.toml uv.lock ./

# Switch to non-root user before installing deps (so .venv is owned by appuser)
USER appuser

# Install dependencies only (production), without building the project itself:
# the code is copied below as a plain module, not installed as a package
RUN uv sync --frozen --no-dev --no-install-project

# Put the venv on PATH so uvicorn and python resolve from it
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1

# Copy application code: src/app on the host -> /app/app in the image
COPY --chown=appuser:appuser src/app/ app/

# Expose port
EXPOSE 8000

# Health check (python:3.12-slim has no curl, so use Python's urllib)
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=5)" || exit 1

# Run uvicorn directly from the venv (no uv run -> no re-sync at runtime)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]