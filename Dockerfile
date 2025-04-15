FROM alpine
RUN apk add --no-cache bash ffmpeg libwebp-tools inotify-tools
COPY --chmod=555 watch.sh /watch.sh 
CMD ["/watch.sh", "/input", "/output"]
VOLUME ["/input", "/output"]