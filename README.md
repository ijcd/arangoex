# Arangoex

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `arangoex` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:arangoex, "~> 0.1.0"}]
    end
    ```

  2. Ensure `arangoex` is started before your application:

    ```elixir
    def application do
      [applications: [:arangoex]]
    end
    ```

## Development

Use ./reset_docker.sh to setup docker and get a copy of the ArangoDB
system password.


## TODO

transaction_test 1
cursor_test 3

bulk_test 4
job_test 5

aql_test 14

cluster_test 8
replication_test 18
