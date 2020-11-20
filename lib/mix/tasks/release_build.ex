defmodule Mix.Tasks.Release.Build do
  use Mix.Task

  @shortdoc "build a tar.gz release in a container and then copy into the current directory"

  def run(args) do
    unless File.exists?("./Dockerfile") do
      Mix.shell().error(
        "No Dockerfile found, please create one before using mix release.build. You can find examples in the README at https://github.com/shareup/release_build#readme"
      )

      Kernel.exit({:shutdown, 1})
    end

    {parsed, _, _} = OptionParser.parse(args, strict: [build_arg: :keep])

    build_args =
      Keyword.get_values(parsed, :build_arg)
      |> Enum.map(&"--build-arg #{&1}")
      |> Enum.join(" ")

    {app, version} = app_and_version()
    tag = "#{app}:#{version}"
    name = "#{app}_#{version}"
    file = "#{name}.tar.gz"

    with :ok <- cmd("docker image build #{build_args} -t #{tag} ."),
         :ok <- cmd("docker container run -dit --rm --name #{name} #{tag}"),
         :ok <- cmd("docker cp #{name}:/release.tar.gz ./#{file}") do
      cleanup(tag, name, args)
      Mix.shell().info("\n\nCopied file #{file} to .")
    else
      {:error, code} ->
        Mix.shell().error("\n\nDocker command failed (#{code}). Trying to cleanup...\n\n")
        cleanup(tag, name, args)
    end
  end

  defp cleanup(tag, name, args) do
    cmd("docker container stop #{name}")
    cmd("docker container rm #{name}")

    if Enum.member?(args, "--cleanup-image") do
      cmd("docker image rm #{tag}")
    end
  end

  @spec cmd(String.t(), keyword) :: :ok | {:error, integer}
  defp cmd(string, opts \\ []) do
    case Mix.shell().cmd(string, opts) do
      0 -> :ok
      code -> {:error, code}
    end
  end

  @spec app_and_version() :: {term, String.t()} | no_return
  @spec app_and_version(keyword) :: {term, String.t()} | no_return
  defp app_and_version,
    do: app_and_version(Mix.Project.get().project())

  defp app_and_version(project) do
    with {:ok, app} <- Keyword.fetch(project, :app),
         {:ok, version} <- Keyword.fetch(project, :version) do
      {app, sanitize_version(version)}
    else
      :error ->
        raise "Could not determine the app and/or version of this project"
    end
  end

  # NOTE: build information can be part of a version after a + for elixir, but
  # docker doens't like a + in an image's name
  defp sanitize_version(version),
    do: String.replace(version, ~r[\+], "-")
end
