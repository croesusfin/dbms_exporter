FROM ncabatoff/dbms_exporter_builder:1.1.5
ARG drivers="freetds"
ARG ldflags="-extldflags=-static"

WORKDIR /build
COPY . .
ENV GOFLAGS="-mod=vendor"
RUN make DRIVERS="$drivers" LDFLAGS="$ldflags"

FROM debian:stable-slim
RUN apt-get update
RUN apt-get -y install libsybdb5
COPY freetds.conf /usr/local/etc/

COPY --from=0 /build/dbms_exporter /
EXPOSE 9113

ENTRYPOINT [ "/dbms_exporter" ]
