FROM debian:bookworm as builder

ARG META_RELEASE=v3.0.2

ENV PYENV_ROOT="/pyenv"
ENV PATH="$PYENV_ROOT/bin:$PATH"

RUN apt-get update && apt-get install \
      vim \
      curl \
      cmake \
      g++ \
      git \
      make \
      build-essential \
      libbz2-dev \
      libffi-dev \
      libjemalloc-dev \
      liblzma-dev \
      libncursesw5-dev \
      libreadline-dev \
      libsqlite3-dev \
      libssl-dev \
      libxml2-dev \
      libxmlsec1-dev \
      tk-dev \
      xz-utils \
      zlib1g-dev \
      -y \
      && apt-get clean all -y

#Install python 3.5
RUN mkdir /pyenv
RUN git clone https://github.com/pyenv/pyenv.git /pyenv
RUN cd /pyenv && src/configure && make -C src
RUN eval "$(pyenv init -)" && pyenv install 3.5.10 && pyenv global 3.5.10

#Install meta toolkit
RUN mkdir -p /meta
COPY . /meta
WORKDIR /meta
RUN git submodule update --init --recursive
RUN mkdir build
COPY config.toml /meta/build/config.toml

#Fix for https://github.com/meta-toolkit/meta/issues/229
RUN sed -i 's;http://download.icu-project.org/files/icu4c/58.2/icu4c-58_2-src.tgz;https://github.com/unicode-org/icu/releases/download/release-58-2/icu4c-58_2-src.tgz;g' CMakeLists.txt

#Dirty hack for https://github.com/meta-toolkit/meta/issues/195
#Run make to pull in dependencies, sed file for locale/xlocale, rerun make
RUN cd build && cmake ../ -DCMAKE_BUILD_TYPE=Release && make || true
RUN sed -i 's/xlocale/locale/' build/deps/icu-58.2/src/ExternalICU/source/i18n/digitlst.cpp
RUN cd build && cmake ../ -DCMAKE_BUILD_TYPE=Release && make

RUN eval "$(pyenv init -)" && pip install metapy pytoml

RUN echo 'eval "$(pyenv init -)"' >> ~/.bashrc

# Define run cmd
CMD ["/bin/bash"]

