FROM alpine:3.20

RUN apk add --no-cache bash coreutils iputils bind-tools

WORKDIR /app
COPY app/app.sh /app/app.sh
RUN chmod +x /app/app.sh

ENTRYPOINT ["/app/app.sh"]
CMD ["help"]
