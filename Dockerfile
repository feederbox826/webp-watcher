FROM alpine AS webp
RUN apk add --no-cache libwebp-tools

FROM alpine
RUN apk add --no-cache bash inotify-tools
COPY --from=webp /usr/bin/cwebp /usr/bin/cwebp
COPY --chmod=555 watch.sh /watch.sh 
CMD ["/watch.sh", "/input", "/output"]
VOLUME ["/input", "/output"]