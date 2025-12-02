FROM ubuntu:22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    apt-transport-https \
    gnupg \
    lsb-release \
    bzip2 \
    libxcb1 \
    libssl3 \
    && curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
    && echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && apt-get install -y kubectl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Goose
RUN ARCH=$(dpkg --print-architecture) && \
    mkdir -p /tmp/goose && \
    if [ "$ARCH" = "amd64" ]; then \
        curl -L -o /tmp/goose/goose.tar.bz2 https://github.com/block/goose/releases/latest/download/goose-x86_64-unknown-linux-gnu.tar.bz2; \
    elif [ "$ARCH" = "arm64" ]; then \
        curl -L -o /tmp/goose/goose.tar.bz2 https://github.com/block/goose/releases/latest/download/goose-aarch64-unknown-linux-gnu.tar.bz2; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    tar -xjf /tmp/goose/goose.tar.bz2 -C /usr/local/bin && \
    rm -rf /tmp/goose && \
    chmod +x /usr/local/bin/goose

# Create app directory
WORKDIR /app

# Create a user for running the application
RUN useradd -m -s /bin/bash goose

# Copy setup script and set permissions
COPY setup-and-run.sh ./
RUN chmod +x setup-and-run.sh && chown goose:goose setup-and-run.sh

# Switch to the goose user
USER goose

# Expose the goose web port
EXPOSE 3000

# Run the setup script
CMD ["./setup-and-run.sh"]
