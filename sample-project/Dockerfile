# Image of the inventory-api sample project.
#
# Written from the documented Dockerfile conventions and NOT built while the course was authored
# (no image may be pulled there). Workflow 06 builds it on GitHub Actions; if the build fails
# there, the failed step's log names the instruction.
#
# The package has no third-party runtime dependencies, so the image needs only the interpreter
# and the source tree.
FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/src

WORKDIR /app
COPY src/ ./src/

# Do not run as root.
RUN useradd --create-home --uid 10001 app
USER app

CMD ["python", "-c", "from inventory_api.stock import main; main()"]
