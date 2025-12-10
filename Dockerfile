# Minimal Goose Container for Kubernetes Demos
FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    bash \
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
    libcairo-gobject2 \
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    libglib2.0-0 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libgcc-s1 \
    libc6 \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl for Kubernetes operations
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        KUBECTL_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        KUBECTL_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${KUBECTL_ARCH}/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Create non-root user
RUN useradd -m -s /bin/bash goose && \
    mkdir -p /home/goose/.config/goose /home/goose/.local/share/goose /home/goose/.kube && \
    chown -R goose:goose /home/goose

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
    curl -L -o goose.tar.bz2 "https://github.com/block/goose/releases/download/v${GOOSE_VERSION}/goose-${GOOSE_ARCH}.tar.bz2" && \
    tar -xjf goose.tar.bz2 && \
    mv goose /usr/local/bin/ && \
    chmod +x /usr/local/bin/goose && \
    rm goose.tar.bz2

# Switch to non-root user
USER goose
WORKDIR /home/goose

# Copy goose configuration
COPY --chown=goose:goose goose-config.yaml /home/goose/.config/goose/config.yaml

# Set environment variables
ENV GOOSE_CONFIG_DIR=/home/goose/.config/goose
ENV GOOSE_DATA_DIR=/home/goose/.local/share/goose
ENV KUBECONFIG=/home/goose/.kube/config
ENV PATH=/usr/local/bin:$PATH

# Expose the web interface port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Start Goose web interface
CMD ["goose", "web", "--host", "0.0.0.0", "--port", "3000"]
