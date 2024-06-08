FROM node:20-bullseye-slim

ENV MARKDOWNLINT_CLI_VERSION=v0.41.0

RUN npm install -g "markdownlint-cli@$MARKDOWNLINT_CLI_VERSION"

ENV REVIEWDOG_VERSION=v0.17.5

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh \
    | sh -s -- -b /usr/local/bin/ ${REVIEWDOG_VERSION}

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD []
