FROM node:24-bookworm-slim@sha256:d6aa754f16b3197301076f047b5def2f02ea1dbbc2ca920407d46d7ec7f87b20

ENV MARKDOWNLINT_CLI_VERSION=v0.49.1

RUN npm install -g "markdownlint-cli@$MARKDOWNLINT_CLI_VERSION"

ENV REVIEWDOG_VERSION=v0.21.2

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh \
    | sh -s -- -b /usr/local/bin/ ${REVIEWDOG_VERSION}

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD []
