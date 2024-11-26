FROM ubuntu:22.04
ENV CODE_SERVER_PORT=8443
ENV GO_VERSION=1.20

RUN apt update && apt install -y \
    curl \
    software-properties-common \
    git \
    sudo

# Install Go
RUN curl -fsSL https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz -o go${GO_VERSION}.tar.gz && \
    tar -C /usr/local -xvzf go${GO_VERSION}.tar.gz && \
    rm go${GO_VERSION}.tar.gz

# Update the PATH environment variable to include Go binary
ENV PATH=$PATH:/usr/local/go/bin

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Create a low-privilege user
RUN useradd -m -s /bin/bash codeuser

# Prepare workspace directory
RUN mkdir -p /config/workspace/.vscode && \
    chown -R codeuser:codeuser /config/workspace

COPY .vscode/ /config/workspace/.vscode/

RUN chmod -R 555 /config/workspace/.vscode && \
chown -R root:root /config/workspace/.vscode

RUN code-server --install-extension golang.go
WORKDIR /config/workspace
COPY . /config/workspace/

# Ensure correct permissions for all files except .vscode
RUN chown -R codeuser:codeuser /config/workspace && \
    find /config/workspace -type d ! -path "*/\.vscode*" -exec chmod 755 {} \; && \
    find /config/workspace -type f ! -path "*/\.vscode/*" -exec chmod 644 {} \;

RUN chown -R root:root /config/workspace/.vscode

# Install Go dependencies
RUN go mod tidy && \
    go install github.com/ctrf-io/go-ctrf-json-reporter/cmd/go-ctrf-json-reporter@latest

# Expose the code-server port
EXPOSE 8443

# Healthcheck
HEALTHCHECK --interval=2s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8443 || exit 1

# Switch to low-privilege user
USER codeuser

# Start code-server with the application workspace
CMD ["code-server", "/config/workspace", "--bind-addr", "0.0.0.0:8443", "--auth", "none"]
