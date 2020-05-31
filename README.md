# Build Release builds a release tar through a docker container

A mix task to build a release in a linux container and then copy it out to the
project's path on the host machine.

If you, like me, work on a mac then the release created on the mac isn't useful
for production: I want to run my apps on linux. This library will build the
release inside a linux docker container and then copy the tar.gz out.  This
also means builds are very repeatable and always created in the same
environment.

## Usage

First, make sure you can build a release:

```sh
$ MIX_ENV=prod mix release
```

Then, place a `Dockerfile` in the project’s root directory. You can find
examples for [ubuntu](#ubuntu) and [debian](#debian) below.

Then, you should be able to:

```sh
$ mix build.release
```

You will now have a `.tar` in your current directory of the release built from inside the container. If you `tar -xf` then the can by started with: `:app_name/bin/:app_name start`

## Installation

Make sure you have docker running. If you can `docker ps` then you are good.
Docker for Mac/Windows is a good app if you are starting from zero.

The package can be installed by adding `build_release` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:build_release, "~> 0.3.0", only: [:dev]}
  ]
end
```

## Example `Dockerfile`s:

### Debian

```Dockerfile
FROM elixir:1.10.3

MAINTAINER Nathan Herald and Anthony Drendel

CMD /bin/bash

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install nodejs -y

ENV MIX_ENV=prod

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix hex.info

WORKDIR /app
RUN mkdir config

COPY mix.exs mix.lock /app/
COPY config/config.exs config/prod.exs config/releases.exs /app/config/

# Must get deps before npm install becuase some javascript is inside some of
# the elixir packages
RUN mix do deps.get --only prod, deps.compile

WORKDIR /app/assets

COPY assets/package.json assets/package-lock.json /app/assets/

RUN npm install

COPY assets /app/assets/
RUN npm run deploy

WORKDIR /app

RUN mix phx.digest

COPY priv /app/priv/
COPY lib /app/lib/

RUN mix compile
RUN mix release

RUN tar -zcf /release.tar.gz -C /app/_build/prod/rel/ .
```

### Ubuntu

```Dockerfile
FROM ubuntu:bionic

MAINTAINER Nathan Herald & Anthony Drendel

ENV OTP_VERSION="22.3.3" \
    REBAR3_VERSION="3.13.1" \
    DEBIAN_FRONTEND="noninteractive"

# We'll install the build dependencies for erlang-odbc along with the erlang
# build process:
RUN set -xe \
	&& OTP_DOWNLOAD_URL="https://github.com/erlang/otp/archive/OTP-${OTP_VERSION}.tar.gz" \
	&& OTP_DOWNLOAD_SHA256="58ef3623cad5f490fdc0719514fe1a9626c8b177a4fb8fa25b5bec0216693eb9" \
	&& runtimeDeps='libodbc1 \
			libsctp1 \
			libwxgtk3.0' \
	&& buildDeps='unixodbc-dev \
			libsctp-dev \
			libwxgtk3.0-dev \
      ca-certificates \
      autoconf \
      git \
      build-essential \
      libncurses-dev \
      openssl \
      libssl-dev \
      curl' \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $runtimeDeps \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& curl -fSL -o otp-src.tar.gz "$OTP_DOWNLOAD_URL" \
	&& echo "$OTP_DOWNLOAD_SHA256  otp-src.tar.gz" | sha256sum -c - \
	&& export ERL_TOP="/usr/src/otp_src_${OTP_VERSION%%@*}" \
	&& mkdir -vp $ERL_TOP \
	&& tar -xzf otp-src.tar.gz -C $ERL_TOP --strip-components=1 \
	&& rm otp-src.tar.gz \
	&& ( cd $ERL_TOP \
	  && ./otp_build autoconf \
	  && ./configure --disable-hipe --without-javac \
	  && make -j$(nproc) \
	  && make install ) \
	&& rm -rf $ERL_TOP /var/lib/apt/lists/*

# elixir expects utf8.
ENV ELIXIR_VERSION="v1.10.3" \
	LANG=C.UTF-8

RUN set -xe \
	&& ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION}.tar.gz" \
	&& ELIXIR_DOWNLOAD_SHA256="f3035fc5fdade35c3592a5fa7c8ee1aadb736f565c46b74b68ed7828b3ee1897" \
	&& curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
	&& echo "$ELIXIR_DOWNLOAD_SHA256  elixir-src.tar.gz" | sha256sum -c - \
	&& mkdir -p /usr/local/src/elixir \
	&& tar -xzC /usr/local/src/elixir --strip-components=1 -f elixir-src.tar.gz \
	&& rm elixir-src.tar.gz \
	&& cd /usr/local/src/elixir \
	&& make install clean

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install nodejs -y

ENV MIX_ENV=prod

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix hex.info

WORKDIR /app
RUN mkdir config

COPY mix.exs mix.lock /app/
COPY config/config.exs config/prod.exs config/releases.exs /app/config/

# Must get deps before npm install becuase some javascript is inside some of
# the elixir packages
RUN mix do deps.get --only prod, deps.compile

WORKDIR /app/assets

COPY assets/package.json assets/package-lock.json /app/assets/

RUN npm install

COPY assets /app/assets/
RUN npm run deploy

WORKDIR /app

RUN mix phx.digest

COPY priv /app/priv/
COPY lib /app/lib/

RUN mix compile
RUN mix release

RUN tar -zcf /release.tar.gz -C /app/_build/prod/rel/ .

CMD /bin/bash
```
