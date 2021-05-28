FROM buildpack-deps:curl

ENV VFLAGS="-cc clang"

RUN set -ex; \
  apt-get update; \
  apt-get install -yqq --no-install-recommends \
    git make clang \
    ; \
  rm -rf /var/lib/apt/lists/*;

RUN curl -sSL https://gobinaries.com/zakuro9715/z | sh;

WORKDIR /usr/local
RUN set -ex; \
  git clone https://github.com/vlang/v && cd v; \
  make; \
  ./v symlink;

ENV COTOWARI_ROOT=/usr/local/cotowari
WORKDIR $COTOWARI_ROOT

COPY . .

RUN ["bash"]
