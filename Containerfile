FROM node:22-bookworm-slim

ARG USER_ID=501
ARG GROUP_ID=20

RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    git \
    curl \
    jq \
    ripgrep \
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
    mkdir -p /workspace /home/prisoner && \
    chown -R ${USER_ID}:${GROUP_ID} /workspace /home/prisoner && \
    chmod 755 /home/prisoner

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER ${USER_ID}:${GROUP_ID}
WORKDIR /workspace
ENV HOME=/home/prisoner
ENV PATH="/usr/local/bin:/home/prisoner/.local/bin:$PATH"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
