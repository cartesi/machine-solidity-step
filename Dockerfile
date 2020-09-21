  
FROM debian:buster as builder
WORKDIR /usr/src/app/
USER root
SHELL ["/bin/bash", "--login", "-c"]

COPY ./contracts ./contracts/
COPY ./test/aleth-assets/ .
COPY ./test/rv64-tests/  ./rv64-tests/
COPY ./yarn.lock .
COPY ./package.json .
COPY ./tsconfig.json .
COPY ./buidler.config.ts .

# copy c++ solidity solc
COPY --from=ethereum/solc:0.7.1 /usr/bin/solc /usr/bin/solc


# Install nodeJS
RUN apt-get -q update && \
    apt-get -qy install \
    curl \
    git \
    python \
    openssl 

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
RUN nvm install 14
RUN npm install -g yarn

# install node/contracts dependencies

# build it
RUN yarn install

# clean up
RUN apt-get purge git curl -qy && \
    apt-get autoremove -qy && \
    apt-get clean && \
    rm -rf ./contracts && \
    rm -rf ./node-modules

# ======================= test runner ============
FROM cartesi/aleth-test:0.2.0
WORKDIR /usr/src/app/
COPY --from=builder /usr/src/app/ . 

ENTRYPOINT [ "./machine-test", "run", "--network", "Istanbul",  "--loads-config", "loads.json",  "--vm=/usr/src/app/lib/libevmone.so"]
