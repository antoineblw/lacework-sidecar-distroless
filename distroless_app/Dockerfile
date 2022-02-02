# Use an official Python runtime as a parent image
#FROM gcr.io/distroless/static-debian11
FROM gcr.io/distroless/static

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
ADD app-src/myapp /app

# Run app.py when the container launches
ENV RUN_CMD "/app/myapp firstArg secondArg thirdArg=34 -f -p=6"
CMD ["/app/app2", "firstArg", "secondArg", "thirdArg=34", "-f", "-p=6"]

