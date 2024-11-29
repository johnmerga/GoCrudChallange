FROM ubuntu:22.04

# Set environment variables
ENV CODE_SERVER_PORT=8443
ENV GO_VERSION=1.20
ENV GOPATH=/config/go
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# Install necessary packages
RUN apt update && apt install -y curl software-properties-common git sudo acl

# Create groups
RUN groupadd -r testgroup && \
    groupadd -r codegroup

# Create users
RUN useradd -m -s /bin/bash -G codegroup codeuser && \
    useradd -r -s /bin/false -G testgroup testuser

# Setup sudo permissions
RUN echo "root ALL=(ALL) ALL" >> /etc/sudoers && \
    echo "codeuser ALL=(root) NOPASSWD: /usr/bin/go mod tidy" >> /etc/sudoers

# Install Go
RUN curl -fsSL https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz -o go${GO_VERSION}.tar.gz && \
    tar -C /usr/local -xvzf go${GO_VERSION}.tar.gz && \
    rm go${GO_VERSION}.tar.gz

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install Go extensions for code-server (optional but useful)
RUN code-server --install-extension golang.go

# Set the working directory to /config/workspace
WORKDIR /config/workspace

# Set up the Go workspace and install Go tools
RUN mkdir -p $GOPATH/src /config/workspace

# Install go-ctrf-json-reporter in the custom GOPATH
RUN go install github.com/ctrf-io/go-ctrf-json-reporter/cmd/go-ctrf-json-reporter@latest
RUN mkdir -p /home/codeuser/.local/share/code-server/User && \
    echo '{"security.workspace.trust.startupPrompt": "never", "security.workspace.trust.enabled": false}' > /home/codeuser/.local/share/code-server/User/settings.json

# Copy project files and set permissions
COPY . .

USER root
RUN go mod tidy
RUN chown -R root:root /config/workspace/.vscode /config/workspace/tests && \
    chmod -R 700 /config/workspace/.vscode /config/workspace/tests && \
    setfacl -R -m u:root:rwx /config/workspace/.vscode /config/workspace/tests && \
    setfacl -R -m u:codeuser:r-x /config/workspace/.vscode /config/workspace/tests && \
    chown -R codeuser:codegroup /config/workspace && \
    chmod -R 755 /config/workspace
RUN chown -R root:root /config/workspace/tests
RUN chown -R root:root /config/workspace/.vscode
USER codeuser


# Expose the code-server port
EXPOSE 8443

# Set a health check for code-server
HEALTHCHECK --interval=2s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8443 || exit 1

# Start code-server with the application workspace
CMD ["code-server", "/config/workspace", "--bind-addr", "0.0.0.0:8443", "--auth", "none"]
