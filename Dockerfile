# Sets python:latest as the builder.
FROM python:latest as builder

# Updates and installs required Linux dependencies.
RUN set -eux; \
    apt-get -y update; \
    apt-get -y upgrade; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Installs required Python dependencies.
COPY requirements_dev.txt /saleor/
WORKDIR /saleor
RUN pip install -r requirements_dev.txt

# Sets python:slim as the release image.
FROM python:slim as release

# Defines new group and user for security reasons.
RUN groupadd -r saleor && useradd -r -g saleor saleor

# Updates and installs required Linux dependencies.
RUN set -eux; \
    apt-get -y update; \
    apt-get -y upgrade; \
    apt-get install -y \
      libcairo2 \
      libgdk-pixbuf2.0-0 \
      liblcms2-2 \
      libopenjp2-7 \
      libpango-1.0-0 \
      libpangocairo-1.0-0 \
      libpq5 \
      libssl1.1 \
      libtiff5 \
      libwebp6 \
      libxml2 \
      mime-support \
      nano \
      shared-mime-info \
    ; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*

# Creates new directories for media and static files.
RUN mkdir -p /saleor/media /saleor/static && chown -R saleor:saleor /saleor/

# Copies Linux binaries, and Python packages from the main builder.
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/lib/python3.9/site-packages/ /usr/local/lib/python3.9/site-packages/

# Copies the source code from the host into the container.
COPY --chown=saleor:saleor . /saleor
WORKDIR /saleor

# Collects the static files into the STATIC_ROOT directory.
ARG STATIC_URL
ENV STATIC_URL ${STATIC_URL:-/static/}
RUN SECRET_KEY=dummy STATIC_URL=${STATIC_URL} python3 manage.py collectstatic --no-input

# Ensures that Python output will be sent to the terminal.
ENV PYTHONUNBUFFERED 1

# Expose the deafult port for Django.
EXPOSE 8000

# Change to the new user for security reasons.
USER saleor
