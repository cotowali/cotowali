ARG vroot="/usr/local/v"
ARG vflags="-cc clang"
ARG cotowali_root=/usr/local/cotowali


# build-deps
# ==========

FROM buildpack-deps:curl AS build-deps

RUN apt-get update \
  && apt-get install -yqq --no-install-recommends \
    git \
    make \
    clang \
  && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://gobinaries.com/zakuro9715/z | sh

ARG vflags
ARG vroot
ENV VFLAGS=$vflags
ENV VROOT=$vroot

RUN git clone https://github.com/vlang/v $VROOT \
  && cd $VROOT \
  && make


# dev-emscripten
# ==============

FROM emscripten/emsdk:latest as dev-emscripten

ARG vflags
ARG vroot
ENV VFLAGS=$vflags
ENV VROOT=$vroot

COPY --from=build-deps $VROOT $VROOT
WORKDIR $VROOT
RUN ./v symlink

ARG cotowali_root
ENV COTOWALI_ROOT=$cotowali_root
WORKDIR $COTOWALI_ROOT

COPY . .

CMD ["bash"]

# dev
# ===

FROM build-deps as dev

ARG vflags
ARG vroot
ENV VFLAGS=$vflags
ENV VROOT=$vroot

COPY --from=build-deps $VROOT $VROOT
WORKDIR $VROOT
RUN ./v symlink

ARG cotowali_root
ENV COTOWALI_ROOT=$cotowali_root
WORKDIR $COTOWALI_ROOT

COPY . .

CMD ["bash"]
