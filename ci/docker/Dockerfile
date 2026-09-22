# Build from the repository root: docker build -f ci/docker/Dockerfile -t stm32-yml-ci:local .
FROM ubuntu:24.04@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3

# OS packages receive Ubuntu updates; exact installed versions are recorded below.
RUN test "$(dpkg --print-architecture)" = amd64 \
    && apt-get -o Acquire::Retries=3 -o APT::Update::Error-Mode=any update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates curl git python3 unzip xz-utils libexpat1 libgmp10 \
    && rm -rf /var/lib/apt/lists/*

COPY ci/dependencies.lock.json /opt/stm32-yml-ci/dependencies.lock.json
COPY ci/docker/install.py /opt/stm32-yml-ci/install.py
RUN python3 /opt/stm32-yml-ci/install.py archives
RUN python3 /opt/stm32-yml-ci/install.py sources

COPY ci/docker/entrypoint.sh /usr/local/bin/stm32-yml-env
COPY ci/docker/verify.py /opt/stm32-yml-ci/verify.py
RUN chmod +x /usr/local/bin/stm32-yml-env \
    && dpkg-query -W > /opt/stm32-yml-ci/packages.txt

ENV CMAKE_USER_HOME=/opt \
    MODULES_DIR=/opt/modules
WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/stm32-yml-env"]
CMD ["python3", "/opt/stm32-yml-ci/verify.py"]

# Verify every CMake/GCC pair while building; no firmware is compiled.
RUN /usr/local/bin/stm32-yml-env python3 /opt/stm32-yml-ci/verify.py
