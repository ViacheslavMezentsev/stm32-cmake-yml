# Context: ci/emulation (keeps firmware/toolchain downloads out of this build).
FROM ubuntu:24.04@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3 AS builder
RUN test "$(dpkg --print-architecture)" = amd64 \
    && apt-get -o Acquire::Retries=3 -o APT::Update::Error-Mode=any update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       ca-certificates curl xz-utils python3 python3-venv build-essential \
       ninja-build libglib2.0-dev libpixman-1-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
COPY versions.lock.json install.py /setup/
RUN python3 /setup/install.py qemu /src/qemu
WORKDIR /src/qemu/build
RUN apt-get -o Acquire::Retries=3 -o APT::Update::Error-Mode=any update \
    && apt-get install -y --no-install-recommends python3-setuptools python3-wheel python3-pip libfdt-dev \
    && rm -rf /var/lib/apt/lists/*
RUN ../configure --prefix=/opt/qemu --target-list=arm-softmmu \
      --without-default-features --enable-tcg --enable-fdt=system --disable-docs --disable-tools \
      --disable-guest-agent --disable-werror --disable-download \
    && ninja -j4 && ninja install
RUN python3 /setup/install.py renode /opt/renode

FROM ubuntu:24.04@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3
RUN apt-get -o Acquire::Retries=3 -o APT::Update::Error-Mode=any update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       python3 libglib2.0-0t64 libpixman-1-0 zlib1g libstdc++6 \
       libicu74 libssl3t64 libunwind8 libuuid1 libgomp1 libfdt1 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /opt/qemu /opt/qemu
COPY --from=builder /opt/renode /opt/renode
COPY versions.lock.json check.py /opt/emulation/
ENV PATH="/opt/qemu/bin:/opt/renode:${PATH}"
RUN dpkg-query -W > /opt/emulation/packages.txt
WORKDIR /workspace
CMD ["python3", "/opt/emulation/check.py", "--locked"]
RUN python3 /opt/emulation/check.py --locked
