defmodule Arango.Config do

  @moduledoc false

  # Generates the configuration for an endpoint.
  # It starts with the defaults for a given environment
  # and then merges in the common config from the Arango config root,
  # and then finally any config specified for the particular endpoint

  @common_config [
    # TODO: do something with debug_requests
    :http_client, :json_codec, :debug_requests, :retries, :username, :password, :host
  ]

  @type t :: %{} | Keyword.t

  @doc """
  Builds a complete set of config for an operation.

  1) Defaults are pulled from `Arango.Config.Defaults`
  2) Common values set via e.g `config :Arango` are merged in.
  3) Keys set on the individual api e.g `config :Arango, :replication` are merged in
  4) Finally, any configuration overrides are merged in
  """
  def new(endpoint, opts \\ []) do
    overrides = Map.new(opts)

    endpoint
    |> build_base(overrides)
    |> retrieve_runtime_config
  end

  def build_base(endpoint, overrides \\ %{}) do
    defaults = Arango.Config.Defaults.get(endpoint)
    common_config = Application.get_all_env(:Arango) |> Map.new |> Map.take(@common_config)
    endpoint_config = Application.get_env(:Arango, endpoint, []) |> Map.new

    defaults
    |> Map.merge(common_config)
    |> Map.merge(endpoint_config)
    |> Map.merge(overrides)
  end

  def retrieve_runtime_config(config) do
    Enum.reduce(config, config, fn
      {:host, host}, config ->
        Map.put(config, :host, retrieve_runtime_value(host, config))
      {:retries, retries}, config ->
        Map.put(config, :retries, retries)
      {:http_opts, http_opts}, config ->
        Map.put(config, :http_opts, http_opts)
      {k, v}, config ->
        case retrieve_runtime_value(v, config) do
          %{} = result -> Map.merge(config, result)
          value -> Map.put(config, k, value)
        end
    end)
  end

  def retrieve_runtime_value({:system, env_key}, _) do
    System.get_env(env_key)
  end
  def retrieve_runtime_value(values, config) when is_list(values) do
    values
    |> Stream.map(&retrieve_runtime_value(&1, config))
    |> Enum.find(&(&1))
  end
  def retrieve_runtime_value(value, _), do: value

  defmodule Defaults do
    @moduledoc """
    Defaults for each endpoint
    """

    @common %{
      scheme: "http",
      host: "localhost",
      port: 8529,

      username: nil,
      password: nil,
      use_auth: :basic,

      headers: %{"Accept" => "*/*"},

      json_codec: Poison,

      # TODO: use these
      retries: [
        max_attempts: 10,
        base_backoff_in_ms: 10,
        max_backoff_in_ms: 10_000
      ],
    }

    @defaults %{
      administration: %{},
      aql: %{},
      bulk: %{},
      cluster: %{},
      collection: %{},
      cursor: %{},
      database: %{},
      document: %{},
      graph: %{},
      graph_edge: %{},
      graph_traversal: %{},
      index: %{},
      job: %{},
      replication: %{},
      simple: %{},
      task: %{},
      transaction: %{},
      user: %{},
      wal: %{},
    }

    @doc """
    Retrieve the default configuration for a endpoint.
    """
    for {endpoint, config} <- @defaults do
      config = Map.merge(config, @common)
      def get(unquote(endpoint)), do: unquote(Macro.escape(config))
    end
  end
end
