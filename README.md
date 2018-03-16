# Arango

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `arango` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:arango, "~> 0.1.0"}]
    end
    ```

  2. Ensure `Arango` is started before your application:

    ```elixir
    def application do
      [applications: [:arango]]
    end
    ```

## Development

Use ./reset_docker.sh to setup docker and get a copy of the ArangoDB
system password.
