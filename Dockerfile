# This Dockerfile defines a multi-stage build to support different configurations for developing, testing, and
# deploying C++ code.
# Any operating system that uses apt should be supported.
ARG OS=ubuntu:latest

# The base stage adds any dependencies that are essential in all stages of developing, testing, and deploying.
FROM ${OS} AS base
RUN apt update \
  && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
  libboost-all-dev \
  # This is a GTSAM optional dependency
  libtbb-dev \
  && rm -rf /var/lib/apt/lists/*

# The dev stage then sets up everything needed for development, such as compilers. It also is where any dependency that
# is built from source is installed.
FROM base AS dev
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
  apt-transport-https \
  build-essential \
  ca-certificates \
  cmake \
  doxygen \
  gdb \
  git \
  && rm -rf /var/lib/apt/lists/*
# Install GTSAM
WORKDIR /opt
ARG GTSAM_VERSION=develop
RUN git clone --branch ${GTSAM_VERSION} --depth 1 https://github.com/borglab/gtsam.git \
  && cmake -S gtsam -B gtsam/build \
  # See https://github.com/borglab/gtsam/blob/develop/INSTALL.md for details
  -DCMAKE_BUILD_TYPE=Debug \
  -DGTSAM_BUILD_CONVENIENCE_LIBRARIES:OPTION=OFF \
  -DGTSAM_BUILD_UNSTABLE:OPTION=OFF \
  && cmake --build gtsam/build --target install \
  && ldconfig
WORKDIR /root
CMD [ "bash" ]

# The test stage is an optional stage that runs the unit tests automatically. While there is some duplication with the
# build stage, this avoids the need for a conditional flag to build tests or not.
FROM dev AS test
COPY . /opt/docker_cpp_stages
WORKDIR /opt/docker_cpp_stages/build
RUN cmake -S /opt/docker_cpp_stages -B /opt/docker_cpp_stages/build \
  && cmake --build .
CMD [ "ctest", "-VV" ]

# The build stage does the compilation for release. It should also recompile any built-from-source dependencies for
# release as well. CMake persists any flags, so you only need to change the build type (and anything else you want to
# change for release).
FROM dev AS build
COPY . /opt/docker_cpp_stages
WORKDIR /opt/docker_cpp_stages/build
RUN xargs rm -rf < /opt/gtsam/build/install_manifest.txt \
  && cmake -S /opt/gtsam -B /opt/gtsam/build -DCMAKE_BUILD_TYPE=Release \
  && cmake --build /opt/gtsam/build --target install
# Now build your software
RUN cmake -S /opt/docker_cpp_stages -B /opt/docker_cpp_stages/build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
  && cmake --build /opt/docker_cpp_stages/build --target install
CMD [ "bash" ]

# The deploy stage is set up to be as minimal as possible. It only contains the OS, any dependencies, and the code you
# just built. This avoids all the unneeded compilers and other build stuff in the image.
FROM base AS deploy
# Copy any locally install code
COPY --from=build /usr/local/ /usr/local/
RUN ldconfig
# Make a local user to avoid admin
RUN useradd -ms /bin/bash user
USER user
WORKDIR /home/user
CMD [ "main" ]