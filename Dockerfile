# syntax=docker/dockerfile:1
FROM debian:bookworm-slim

ARG HCE_VERSION=0.1.0
ARG TARGETARCH

# Install jq, curl, and CA certs
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl jq ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Pull the correct CLI binary based on architecture
RUN set -eux; \
    case "${TARGETARCH:-amd64}" in \
      amd64)  url="https://app.harness.io/public/shared/tools/chaos/hce-cli/${HCE_VERSION}/hce-cli-${HCE_VERSION}-linux-amd64" ;; \
      arm64|aarch64) url="https://app.harness.io/public/shared/tools/chaos/hce-cli/${HCE_VERSION}/hce-cli-${HCE_VERSION}-linux-arm64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac; \
    curl -fL "$url" -o /usr/local/bin/hce_cli_api && \
    chmod +x /usr/local/bin/hce_cli_api

# Copy the run script into the container
WORKDIR /work
COPY run_chaos.sh /usr/local/bin/run_chaos.sh
RUN chmod +x /usr/local/bin/run_chaos.sh

# Default command
ENTRYPOINT ["/usr/local/bin/run_chaos.sh"]

