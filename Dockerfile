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

# Sets python:slim as the final image.
FROM python:slim

# Defines new group and user for security reasons.
RUN groupadd -r saleor && useradd -r -g saleor saleor

# Updates and installs required Linux dependencies.
RUN apt-get update \
  && apt-get install -y \
  libcairo2 \
  libgdk-pixbuf2.0-0 \
  liblcms2-2 \
  libopenjp2-7 \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  libssl1.1 \
  libtiff5 \
  libwebp6 \
  libxml2 \
  libpq5 \
  shared-mime-info \
  mime-support \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Creates new directories for media, and static files.
RUN mkdir -p /saleor/media /saleor/static && chown -R saleor:saleor /saleor/

# Copies Python packages and binaries from the main builder.
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/lib/python3.9/site-packages/ /usr/local/lib/python3.9/site-packages/

# Copies the source code from the host into the container.
COPY . /saleor
WORKDIR /saleor

# todo: need to understand.
ARG STATIC_URL
ENV STATIC_URL ${STATIC_URL:-/static/}
RUN SECRET_KEY=dummy STATIC_URL=${STATIC_URL} python3 manage.py collectstatic --no-input

# Ensures that Python output will be sent to the terminal.
ENV PYTHONUNBUFFERED 1

# Expose the deafult port for Django.
EXPOSE 8000

# Change to the new user for security reasons.
USER saleor
