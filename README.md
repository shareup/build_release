# Build Release builds a release tar through a docker container

A Dockerfile combined with a mix task to build a distillery release in the
linux container and then copy it to the project's path.

If you, like me, work on a mac then the release you just created isn't
that useful. I want to run my apps on linux. So, it's not that big a
deal to build the release inside a linux docker container and then
copy the tar.gz out.  This also means builds are very repeatable and
always created in the same environment and I guess that is good too.

## Usage

First, make sure you can build a relase with distillery:

```sh
$ mix release --env prod
```

If that works then your project can be built. So:

```sh
$ mix build.release
```

That's it.

A Dockerfile is provided for you.

## Installation

Make sure you have docker running. If you can `docker ps` then you are
good. Docker for Mac/Windows is a good app now a days and I recommend
it.

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `build_release` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:build_release, "~> 0.1.0"}
  ]
end
```

**Note: this package does not depend on distillery so you need to also have that listed in your deps.**

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/build_release](https://hexdocs.pm/build_release).
