FROM perl:latest
LABEL maintainer="Michael D. Stemle, Jr. <themanchicken@gmail.com>"

# Install the package manager.
RUN cpanm Carton

# Set up the data dir
RUN mkdir -p /app-data
ENV TRAWLER_DATA_DIR=/app-data

# Set up the app dir
RUN mkdir -p /app
COPY ./ /app/
WORKDIR /app/

# Move the startup-data to the data dir.
RUN mv /app/startup-data/* /app-data
RUN rm -rf /app/startup-data

# Set up dependencies
RUN carton install --deployment
EXPOSE 3000/tcp

# Set the entry-point to the runner.
ENTRYPOINT [ "./runner.sh" ]