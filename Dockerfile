  
FROM debian:buster as builder
WORKDIR /usr/src/app/
USER root
SHELL ["/bin/bash", "--login", "-c"]

COPY ./contracts ./contracts/
COPY ./test/aleth-assets/ .
COPY ./prepare_byte_codes.sh .
COPY ./yarn.lock .
COPY ./package.json .

# copy c++ solidity solc
COPY --from=ethereum/solc:0.5.14 /usr/bin/solc /usr/bin/solc


# Install nodeJS
RUN apt-get -q update && \
    apt-get -qy install \
    curl \
    git \
    python \
    openssl 

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
RUN nvm install 12
RUN npm install -g yarn

# install node/contracts dependencies

# --ignore-scripts to ignore truffle prepare hook
RUN yarn install --ignore-scripts

# build it
RUN /bin/bash prepare_byte_codes.sh

# clean up
RUN apt-get purge git curl -qy && \
    apt-get autoremove -qy && \
    apt-get clean && \
    rm -rf ./contracts && \
    rm -rf ./node-modules

# ================= Bin Files ==============
FROM debian:buster as bin-builder
WORKDIR /usr/src/app/
COPY ./test/rv64-tests.zip .
RUN apt-get -q update && \
    apt-get -qy install \
    wget \
    brotli \
    unzip  
RUN unzip rv64-tests.zip -d . && \
    cd rv64-tests
# clean up
RUN apt-get purge brotli wget unzip -qy && \
    apt-get autoremove -qy && \
    apt-get clean

FROM scratch as bin-files
COPY --from=bin-builder /usr/src/app/rv64-tests/ /usr/src/app/rv64-tests/

# ======================= test runner ============
FROM cartesi/aleth-test
WORKDIR /usr/src/app/
COPY --from=bin-files /usr/src/app/rv64-tests/ /usr/src/app/rv64-tests/
COPY --from=builder /usr/src/app/ . 

ENTRYPOINT [ "./machine-test", "run", "--network", "Istanbul",  "--loads-config", "loads.json",  "--vm=/usr/src/app/lib/libevmone.so"]
