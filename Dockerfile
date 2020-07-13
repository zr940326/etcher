FROM balenalib/aarch64-debian-node:12.16-buster-build as builder

RUN apt-get update
RUN apt-get install python

WORKDIR /usr/src/app

ENV npm_config_disturl=https://electronjs.org/headers
ENV npm_config_runtime=electron
ENV npm_config_target=9.0.3

COPY src src
COPY scripts scripts
COPY typings typings
COPY binding.gyp tsconfig.json npm-shrinkwrap.json package.json ./

RUN npm i

COPY assets assets
COPY lib lib
COPY tsconfig.json webpack.config.ts electron-builder.yml afterPack.js ./

RUN npm run webpack
RUN PATH=$(pwd)/node_modules/.bin/:$PATH electron-builder --dir --config.asar=false --config.npmRebuild=false --config.nodeGypRebuild=false

FROM alexisresinio/aarch64-debian-bejs:latest
# Etcher configuration
COPY etcher-pro-config.json /usr/src/app/

COPY --from=builder /usr/src/app/dist/linux-arm64-unpacked/resources/app /usr/src/app
COPY --from=builder /usr/src/app/node_modules/electron/ /usr/src/app/node_modules/electron
WORKDIR /usr/src/app/node_modules/.bin
RUN ln -s ../electron/cli.js electron
WORKDIR /usr/src/app

ENV ELECTRON_ENABLE_LOGGING=1

ENV UDEV=1

RUN mkdir /tmp/media
ENV BALENA_ELECTRONJS_MOUNTS_ROOT=/tmp/media
ENV BALENA_ELECTRONJS_CONSTRAINT_PATH=/tmp/media

CMD cp -n /usr/src/app/etcher-pro-config.json /root/.config/balena-etcher/config.json && xinit
