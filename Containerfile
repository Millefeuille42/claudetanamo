# syntax=docker/dockerfile:1
FROM node:22-bookworm-slim@sha256:c3de60bf2f9dd0ac6370e6117950ff62d6e339527e7472301c9c78a017978392

ARG USER_ID=501
ARG GROUP_ID=20

RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    git \
    curl \
    jq \
    xz-utils \
    procps \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

ARG CLAUDE_CODE_VERSION=2.1.296
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

RUN if getent group ${GROUP_ID} >/dev/null; then \
      EXISTING_GROUP=$(getent group ${GROUP_ID} | cut -d: -f1); \
    else \
      groupadd -g ${GROUP_ID} prisoner && EXISTING_GROUP=prisoner; \
    fi && \
    useradd -m -u ${USER_ID} -g ${EXISTING_GROUP} -s /bin/bash prisoner && \
    mkdir -p /workspace /home/prisoner /nix && \
    chown -R ${USER_ID}:${GROUP_ID} /workspace /home/prisoner /nix && \
    chmod 755 /home/prisoner

USER ${USER_ID}:${GROUP_ID}
WORKDIR /workspace
ENV HOME=/home/prisoner

ARG NIX_VERSION=2.35.2
ARG NIX_INSTALL_SHA256=9adda97297d9e8ab360df95c729eabff4f4f93d6db091953c3a68f29e3fb130c
RUN curl -fsSL -o /tmp/nix-install "https://releases.nixos.org/nix/nix-${NIX_VERSION}/install" && \
    echo "${NIX_INSTALL_SHA256}  /tmp/nix-install" | sha256sum -c - && \
    sh /tmp/nix-install --no-daemon && \
    rm /tmp/nix-install

RUN mkdir -p /home/prisoner/.config/nix && \
    echo "experimental-features = nix-command flakes" >> /home/prisoner/.config/nix/nix.conf

ENV PATH="/home/prisoner/.nix-profile/bin:/home/prisoner/.local/bin:/usr/local/bin:$PATH"

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]