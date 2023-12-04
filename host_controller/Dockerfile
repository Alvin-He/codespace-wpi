FROM rust:latest as builder
WORKDIR /build
COPY /api .
RUN cargo build --bin web_gateway -r

FROM nginx
COPY --from=builder /build/target/release/web_gateway /api/web_gateway
COPY nginx/nginx.conf /etc/nginx/nginx.conf
ADD ./start_up.bash /start_up.bash
ENTRYPOINT [ "/start_up.bash" ]
# DO NOT SET CMD, otherwise nginx won't boot