FROM gcr.io/distroless/static

# Set the working directory to /app
WORKDIR /lacework


ADD runlacework /lacework

COPY --from=lacework/datacollector:latest-sidecar /var/lib/lacework-backup /var/lib/lacework-backup
COPY --from=lacework/datacollector:latest-sidecar /lib/ld-musl-x86_64.so.1 /lacework/lib/ld-musl-x86_64.so.1


VOLUME /lacework
VOLUME /var/lib/lacework-backup

CMD ["/lacework/runlacework"]

