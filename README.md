# Build Release builds a release tar through a docker container

A Dockerfile combined with a mix task to build a release in a linux container
and then copy it out to the project's path on the host machine.

If you, like me, work on a mac then the release created on the mac isn't useful
for production: I want to run my apps on linux. This library will build the
release inside a linux docker container and then copy the tar.gz out.  This
also means builds are very repeatable and always created in the same
environment and I guess that is good too.

## Usage

First, make sure you can build a release:

```sh
$ MIX_ENV=prod mix release
```

If that works then you should be able to:

```sh
$ mix build.release
```

That's it.

A [Dockerfile is provided for you](/priv/Dockerfile). You can provide your own
Dockerfile at the root of your project if you need custom build steps.

## Installation

Make sure you have docker running. If you can `docker ps` then you are
good. Docker for Mac/Windows is a good app now a days and I recommend
it.

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `build_release` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:build_release, "~> 0.2.0", only: [:dev]}
  ]
end
```
