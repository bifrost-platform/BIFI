FROM ethereum/solc:0.6.12-alpine

LABEL "com.github.actions.name"="Solidity 0.6 Compile"
LABEL "com.github.actions.description"="CI for solidity"
LABEL "com.github.actions.icon"="archive"
LABEL "com.github.actions.color"="orange"

RUN apk update && apk add bash
RUN apk add jq

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
