FROM node:18-alpine3.14

ENV MARKDOWNLINT_CLI_VERSION=v0.37.0

RUN npm install -g "markdownlint-cli@$MARKDOWNLINT_CLI_VERSION"

ENV REVIEWDOG_VERSION=v0.15.0

RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh \
    | sh -s -- -b /usr/local/bin/ ${REVIEWDOG_VERSION}
RUN apk --no-cache -U add git

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD []
