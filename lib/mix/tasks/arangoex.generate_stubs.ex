defmodule Mix.Tasks.Arangoex.GenerateStubs do
  use Mix.Task

  import Focus
  alias Lens

  @shortdoc "Generate API clients from swagger.json"
  @preferred_cli_env "dev"

  def run(_args) do
    swagger_file = "swagger_with_additions.json"
    
    swagger =
      swagger_file
      |> File.read!
      |> Poison.decode!

    swagger
    |> parse_swagger
  end

  def parse_swagger(swagger) do
    rootLenses = Lens.make_lenses(swagger)

    base_path = Lens.make_lens("basePath")
    definitions = Lens.make_lens("definitions")
    info = Lens.make_lens("info")
    paths = Lens.make_lens("paths")
    schemes = Lens.make_lens("schemes")
    version = Lens.make_lens("swagger")

    system_path = swagger["basePath"]
    |> IO.inspect

    description = swagger["info"]["description"]
    |> IO.inspect
    title = swagger["info"]["title"]    
    |> IO.inspect
    api_version = swagger["info"]["version"]
    |> IO.inspect
    
    paths =
      swagger["paths"]
      |> Map.to_list
      |> List.first
      |> IO.inspect


    
    # %{"paths" => paths} = swagger

    # tags = for {_path, path_methods} <- paths, {method, %{"tags" => tags}} <- path_methods, do: tags

    # tags
    # |> List.flatten
    # |> Enum.uniq
    # |> Enum.map(&Macro.camelize/1)
    # |> Enum.map(fn s -> Regex.replace(~r/\w/, s, "") end)
  end
 
  #   for {"paths", paths} <- swagger do
  #     paths |> Enum.count |> IO.inspect(label: "Path count")

  #     sections = []
  #     for {path, path_methods} <- paths do
  #       path |> IO.inspect(label: "Path")

  #       for {method, %{"operationId" => operation_id, "tags" => tags}} <- path_methods do
  #         sections = sections ++ tags
  #         sections |> IO.inspect(label: "Sections")
  #         IO.puts("#{tags}  #{method}  #{operation_id}")
  #       end

  #       sections |> IO.inspect(label: "Sections")
  #     end
  #   end
  # end
end
