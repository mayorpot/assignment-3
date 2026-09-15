FROM alpine:3.22

LABEL maintainer="DevOps Assignment"
LABEL description="Containerized DevOps diagnostic CLI"

RUN apk add --no-cache \
    bash \
    coreutils \
    iproute2 \
    iputils \
    procps \
    bind-tools \
    netcat-openbsd

WORKDIR /app

COPY app/app.sh /app/app.sh

RUN chmod +x /app/app.sh

ENTRYPOINT ["/app/app.sh"]

CMD ["help"]