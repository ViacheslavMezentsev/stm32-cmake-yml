# Context: repository root (for tools/qemu); .dockerignore drops .git and build.
# QEMU is not compiled here: tools/qemu holds the prebuilt archive made from the
# pinned release source by tools/qemu/build-linux.sh on this Ubuntu base.
FROM ubuntu:24.04@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3 AS builder
RUN test "$(dpkg --print-architecture)" = amd64 \
    && apt-get -o Acquire::Retries=3 -o APT::Update::Error-Mode=any update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       ca-certificates curl xz-utils python3 \
    && rm -rf /var/lib/apt/lists/*
COPY ci/emulation/versions.lock.json ci/emulation/install.py /setup/
COPY tools/qemu/ /setup/tools/qemu/
RUN python3 /setup/install.py qemu /opt/qemu
RUN python3 /setup/install.py renode /opt/renode

FROM ubuntu:24.04@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3
RUN apt-get -o Acquire::Retries=3 -o APT::Update::Error-Mode=any update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       python3 libglib2.0-0t64 zlib1g libstdc++6 \
       libicu74 libssl3t64 libunwind8 libuuid1 libgomp1 libfdt1 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /opt/qemu /opt/qemu
COPY --from=builder /opt/renode /opt/renode
COPY ci/emulation/versions.lock.json ci/emulation/check.py /opt/emulation/
ENV PATH="/opt/qemu/bin:/opt/renode:${PATH}"
RUN dpkg-query -W > /opt/emulation/packages.txt
WORKDIR /workspace
CMD ["python3", "/opt/emulation/check.py", "--locked"]
RUN python3 /opt/emulation/check.py --locked
