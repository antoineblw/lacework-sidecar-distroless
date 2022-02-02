FROM gcr.io/distroless/static

# Set the working directory to /app
WORKDIR /lacework

ADD runlacework /lacework
#ADD datacollector/datacollector /lacework

# Hacked version of Lacework datacollector
# This will be replaced with a statically compiled version of datacollector
ADD datacollector/bin/datacollector /lacework
ADD datacollector/lib/ld-musl-x86_64.so.1 /lacework/lib/ld-musl-x86_64.so.1

VOLUME /lacework

CMD ["/lacework/runlacework"]

