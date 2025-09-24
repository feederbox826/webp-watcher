FROM alpine:edge
RUN apk add --no-cache libwebp-tools inotify-tools ffmpeg sqlite
COPY --chmod=555 watch.sh db.sh /
ENV DB_FILE=/db/webp-watcher.sqlite3
CMD ["/watch.sh", "/input", "/output"]
VOLUME ["/input", "/output", "/db"]