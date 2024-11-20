FROM --platform=$BUILDPLATFORM messense/rust-musl-cross:x86_64-musl AS server_builder_amd64
FROM --platform=$BUILDPLATFORM messense/rust-musl-cross:aarch64-musl AS server_builder_arm64
FROM server_builder_${TARGETARCH} AS server_builder

ARG TARGETARCH

WORKDIR /aw-server-rust

RUN if [ $TARGETARCH = "amd64" ]; then \
      echo "x86_64" > /arch; \
    elif [ $TARGETARCH = "arm64" ]; then \
      echo "aarch64" > /arch; \
    else \
      echo "Unsupported platform: $TARGETARCH"; \
      exit 1; \
    fi


ENV AW_SERVER_RUST_HASH=a0cdef90cf86cd8d2cc89723f5751c1123ae7e2b

RUN git clone https://github.com/ActivityWatch/aw-server-rust . && \
    git checkout $AW_SERVER_RUST_HASH && \
    cargo build --release --target $(cat /arch)-unknown-linux-musl && \
    mv /aw-server-rust/target/$(cat /arch)-unknown-linux-musl/release/aw-server /aw-server

FROM --platform=$BUILDPLATFORM alpine:3.20.3 AS web_builder

WORKDIR /aw-webui

ENV AW_WEBUI_VERSION=v0.13.2
ENV AW_ZIP_HASH=8f62b10babf8a8f108cbdf7267c02fbc1ce2a970fa9535f230b3416b803e3360

RUN wget https://github.com/ActivityWatch/activitywatch/releases/download/$AW_WEBUI_VERSION/activitywatch-$AW_WEBUI_VERSION-linux-x86_64.zip && \
    echo "$AW_ZIP_HASH  activitywatch-$AW_WEBUI_VERSION-linux-x86_64.zip" | sha256sum -c && \
    unzip activitywatch-$AW_WEBUI_VERSION-linux-x86_64.zip && \
    rm activitywatch-$AW_WEBUI_VERSION-linux-x86_64.zip

FROM alpine:3.20.3

WORKDIR /app

COPY --from=server_builder /aw-server /app/aw-server
COPY --from=server_builder /aw-server-rust/LICENSE /app/LICENSE
COPY --from=web_builder /aw-webui/activitywatch/aw-server/aw_server/static /app/static

RUN mkdir /data

EXPOSE 5600

CMD ["./aw-server", "--dbpath", "/data/sqlite.db", "--webpath", "/app/static", "--host", "0.0.0.0"]
