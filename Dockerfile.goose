FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    wget \
    unzip \
    bzip2 \
    libxcb1 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libxrandr2 \
    libasound2 \
    libatk1.0-0 \
    libcairo2 \
    libdrm2 \
    libgtk-3-0 \
    libgbm1 \
    libnss3 \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl for Kubernetes operations
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Create non-root user
RUN useradd -m -s /bin/bash goose && \
    mkdir -p /home/goose/.config/goose /home/goose/.local/share/goose /home/goose/.local/state/goose/logs && \
    chown -R goose:goose /home/goose && \
    chmod -R 755 /home/goose/.local

# Download and install Goose binary
ARG GOOSE_VERSION=1.15.0
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        GOOSE_ARCH="x86_64-unknown-linux-gnu"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        GOOSE_ARCH="aarch64-unknown-linux-gnu"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget -O goose.tar.bz2 "https://github.com/block/goose/releases/download/v${GOOSE_VERSION}/goose-${GOOSE_ARCH}.tar.bz2" && \
    tar -xjf goose.tar.bz2 && \
    mv goose /usr/local/bin/ && \
    chmod +x /usr/local/bin/goose && \
    rm goose.tar.bz2

# Switch to non-root user
USER goose
WORKDIR /home/goose

# Expose the web interface port
EXPOSE 3000

# Set environment variables
ENV GOOSE_CONFIG_DIR=/home/goose/.config/goose
ENV GOOSE_DATA_DIR=/home/goose/.local/share/goose
ENV GOOSE_LOGS_DIR=/home/goose/.local/state/goose/logs
ENV PATH=/usr/local/bin:$PATH
ENV KUBECONFIG=/home/goose/.kube/config

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Start Goose web interface
CMD ["goose", "web", "--host", "0.0.0.0", "--port", "3000"]
