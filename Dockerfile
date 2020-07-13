FROM perl:latest
LABEL maintainer="Michael D. Stemle, Jr. <themanchicken@gmail.com>"

# Install the package manager.
RUN cpanm Carton

# Set up the data dir
RUN mkdir -p /app-data
ENV TRAWLER_DATA_DIR=/app-data

# Set up the app dir, move the cpanfile
RUN mkdir -p /app
COPY ./cpanfile /app/
COPY ./cpanfile.snapshot /app/
WORKDIR /app/

# Set up dependencies
RUN carton install --deployment

# Copy over the code.
COPY ./ /app/

# Move the startup-data to the data dir.
RUN mv /app/startup-data/* /app-data
RUN rm -rf /app/startup-data

EXPOSE 3000/tcp

# Set the entry-point to the runner.
CMD [ "./runner.sh", "web" ]
