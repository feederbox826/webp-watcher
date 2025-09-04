FROM alpine:edge
RUN apk add --no-cache libwebp-tools inotify-tools
COPY --chmod=555 watch.sh /watch.sh 
CMD ["/watch.sh", "/input", "/output"]
VOLUME ["/input", "/output"]