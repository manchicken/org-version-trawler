FROM perl:latest
#FROM perl:5.32-slim
LABEL maintainer="Michael D. Stemle, Jr. <themanchicken@gmail.com>"

# Install the package manager.
RUN cpanm Carton

# Set up the data dir
RUN mkdir -p /app-data
ENV TRAWLER_DATA_DIR=/app-data
COPY ./startup-data/* /app-data

# Set up the app dir, move the cpanfile
RUN mkdir -p /app
WORKDIR /app
COPY cpanfile cpanfile
COPY cpanfile.snapshot cpanfile.snapshot

# Set up dependencies
RUN carton install --deployment

# Copy over the code.
COPY lib lib
COPY bin bin
COPY trawl_web trawl_web
COPY runner.sh runner.sh

EXPOSE 3000/tcp

CMD ["carton", "exec", "./trawl_web/script/trawl_web", "daemon"]
