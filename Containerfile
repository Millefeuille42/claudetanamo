# syntax=docker/dockerfile:1
FROM node:22-bookworm-slim

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

RUN npm install -g @anthropic-ai/claude-code

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

RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon

RUN mkdir -p /home/prisoner/.config/nix && \
    echo "experimental-features = nix-command flakes" >> /home/prisoner/.config/nix/nix.conf

ENV PATH="/home/prisoner/.nix-profile/bin:/home/prisoner/.local/bin:/usr/local/bin:$PATH"

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]