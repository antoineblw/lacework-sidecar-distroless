FROM gcr.io/distroless/static

# Set the working directory to /app
WORKDIR /lacework

ADD runlacework /lacework

# Hacked version of Lacework datacollector
# This will be replaced with a statically compiled version of datacollector
# This has a later version of the datacollector (the one in lacework image is old)
ADD datacollector/bin/datacollector /lacework

COPY --from=lacework/datacollector:latest-sidecar /var/lib/lacework-backup /var/lib/lacework-backup
COPY --from=lacework/datacollector:latest-sidecar /lib/ld-musl-x86_64.so.1 /lacework/lib/ld-musl-x86_64.so.1


VOLUME /lacework
VOLUME /var/lib/lacework-backup

CMD ["/lacework/runlacework"]

