defmodule Mix.Tasks.Arangoex.MergeSwagger do
  use Mix.Task

  @shortdoc "Merge swagger_merge.json with swagger.json"
  @preferred_cli_env "dev"

  def run(_args) do
    upstream_file = "swagger.json"
    additions_file = "swagger_additions.json"    
    output_file = "swagger_with_additions.json"

    
    # read original swagger.json
    upstream =
      upstream_file
      |> File.read!
      |> Poison.decode!

    # read additions we maintain
    to_merge =
      additions_file
      |> File.read!
      |> Poison.decode!

    # merge and write out
    merged = DeepMerge.deep_merge(upstream, to_merge)
    File.write!(output_file, Poison.encode!(merged, pretty: true))

    IO.puts("Succesfully wrote #{output_file}")
  end
end
