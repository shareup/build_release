defmodule Mix.Tasks.Build.Release do
  use Mix.Task

  @shortdoc "build a tar.gz release in a container and then copy into the current directory"

  def run(args) do
    {app, version} = app_and_version()
    tag = "#{app}:#{version}"
    name = "#{app}_#{version}"
    file = "#{name}.tar.gz"

    copy_dockerfile()

    with :ok <- cmd("docker image build -t #{tag} ."),
         :ok <- cmd("docker container run -dit --rm --name #{name} #{tag}"),
         :ok <-
           cmd(
             "docker cp #{name}:/app/_build/prod/rel/#{app}/releases/#{version}/#{app}.tar.gz ./#{
               file
             }"
           ) do
      cleanup(tag, name, args)
      Mix.shell().info("\n\nCopied file #{file} to .")
    else
      {:error, code} ->
        Mix.shell().error("\n\nDocker command failed (#{code}). Trying to cleanup...\n\n")
        cleanup(tag, name, args)
    end
  end

  defp dockerfile_path,
    do: Application.app_dir(:build_release, ["priv", "Dockerfile"])

  defp copy_dockerfile do
    unless File.exists?("./Dockerfile") do
      File.cp(dockerfile_path(), "./Dockerfile")
      Mix.shell().info("Created Dockerfile. Please add this to your version control.\n\n")
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
      {app, version}
    else
      :error ->
        raise "Could not determine the app and/or version of this project"
    end
  end
end
