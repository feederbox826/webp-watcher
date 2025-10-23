FROM alpine:edge AS ffmpeg

# FFmpeg build deps
RUN apk add --no-cache \
    build-base \
    nasm \
    yasm \
    pkgconfig \
    libwebp-dev \
    libvpx-dev \
    libopusenc-dev

ADD https://github.com/FFmpeg/FFmpeg.git /usr/src/ffmpeg
WORKDIR /usr/src/ffmpeg
# set CFLAGS (march via runner)
ARG CFLAGS="-O2 -march=native -mtune=native"
RUN ./configure \
  --prefix=/usr/local \
  --disable-debug \
  --disable-doc \
  --disable-ffprobe \
  --disable-ffplay \
  --disable-everything \
  --disable-static \
  --enable-shared \
  # WebM support (video + audio)
  --enable-libvpx \
  --enable-decoder=vp8,vp9,opus \
  --enable-demuxer=webm,matroska \
  # WebP support
  --enable-libwebp \
  --enable-encoder=libwebp \
  --enable-muxer=webp,image2 \
  # reading/writing files
  --enable-protocol=file \
  # compilation runtime options
  --enable-lto=auto \
  --enable-small \
  && make -j$(nproc) \
  && make install
RUN strip /usr/local/bin/ffmpeg
RUN strip --strip-unneeded /usr/local/lib/*.so*
RUN \
  echo "**** file cleanup ****" && \
  rm -r \
    /usr/local/lib/pkgconfig \
    /usr/local/share \
    /usr/local/include

FROM alpine:edge AS final
COPY --from=ffmpeg /usr/local /usr/local
RUN apk add --no-cache bash libwebp-tools libvpx inotify-tools sqlite
COPY --chmod=555 watch.sh db.sh /
ENV DB_FILE=/db/webp-watcher.sqlite3
ENTRYPOINT ["/bin/bash"]
CMD ["/watch.sh", "/input", "/output"]
VOLUME ["/input", "/output", "/db"]