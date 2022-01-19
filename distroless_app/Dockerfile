# Use an official Python runtime as a parent image
#FROM gcr.io/distroless/static-debian11
FROM gcr.io/distroless/static

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
ADD app-src/app1 /app
ADD app-src/app2 /app

# Run app.py when the container launches
CMD ["/app/app2"]

