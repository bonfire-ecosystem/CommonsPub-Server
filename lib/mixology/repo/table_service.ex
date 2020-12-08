# SPDX-License-Identifier: AGPL-3.0-only
defmodule Pointers.Tables do
  @moduledoc """
  An ets-based cache that allows table up Table objects by:

  * Database ID (integer)
  * Table name (string)
  * Ecto module name (atom)

  On startup:
  * The database is queried for a list of tables
  * The application is queried for a list of ecto schema modules
  * The two are collated, ensuring that schema modules exist for all tables
  * The data is inserted into an ets table owned by the process

  During operation, table requests will hit ets directly - this
  service exists solely to own the table and fit into the OTP
  supervision hierarchy neatly...
  """

  require Logger

  alias Bonfire.Repo.Introspection
  alias Bonfire.Common.Errors.TableNotFoundError

  alias Pointers.Table

  @repo Application.get_env(:bonfire_common, :repo_module)

  use GenServer

  @init_query_name __MODULE__
  @service_name __MODULE__
  @table_name __MODULE__.Cache

  @type table_id :: binary() | integer() | atom()
  @type lookup_error :: {:error, term}

  # public api

  @doc "Starts up the service registering it locally under this module's name"
  def start_link(_),
    do: GenServer.start_link(__MODULE__, name: @service_name)

  @doc false
  def init(_) do
    IO.inspect(repo: @repo)
    try do
      Table
      |> @repo.all(telemetry_event: @init_query_name)
      # |> IO.inspect
      |> pair_schemata()
      # |> IO.inspect
      |> populate_table()

      Logger.info("TableService started")

      {:ok, []}
    rescue
      e ->
        Logger.warn("TableService could not init because: #{inspect(e, pretty: true)}")
        {:ok, []}
    end
  end

  @doc "Lists all tables we know"
  def list_all() do
    case :ets.table(@table_name, :ALL) do
      [{_, r}] -> r
      _ -> []
    end
  end

  def list_pointable_schemas() do
    pointable_tables = list_all()

    Enum.reduce(pointable_tables, [], fn x, acc ->
      Enum.concat(acc, [x.schema])
    end)
  end

  @spec table(table_id()) :: {:ok, Table.t()} | {:error, TableNotFoundError.t()}
  @doc "Look up a Table by name, id or ecto module"
  def table(key) when is_integer(key) or is_binary(key) or is_atom(key),
    do: lookup_result(key, :ets.table(@table_name, key))

  defp lookup_result(key, []), do: {:error, TableNotFoundError.new(key)}
  defp lookup_result(_, [{_, v}]), do: {:ok, v}

  @spec table!(table_id()) :: Table.t()
  @doc "Look up a Table by name or id, throw TableNotFoundError if not found"
  def table!(key) do
    case table(key) do
      {:ok, v} -> v
      {:error, reason} -> throw(reason)
    end
  end

  @spec id(table_id()) :: {:ok, integer()} | {:error, TableNotFoundError.t()}
  @doc "Look up a table id by id, name or schema"
  def id(key) do
    with {:ok, val} <- table(key), do: {:ok, val.id}
  end

  @spec id!(table_id()) :: integer()
  @doc "Look up up a table id by id, name or schema, throw TableNotFoundError if not found"
  def id!(key) do
    case id(key) do
      {:ok, v} -> v
      {:error, reason} -> throw(reason)
    end
  end

  @doc false
  def ids!(ids) do
    Enum.map(ids, fn t ->
      cond do
        # cheat to save some lookups
        is_binary(t) -> t
        is_atom(t) -> id!(t)
      end
    end)
  end

  @spec schema(table_id()) :: {:ok, atom()} | {:error, TableNotFoundError.t()}
  @doc "Look up a schema module by id, name or schema"
  def schema(key) do
    with {:ok, val} <- table(key), do: {:ok, val.schema}
  end

  @spec schema!(table_id()) :: atom()
  @doc "Look up a schema module by id, name or schema, throw TableNotFoundError if not found"
  def schema!(key) do
    case schema(key) do
      {:ok, v} -> v
      {:error, reason} -> throw(reason)
    end
  end

  # callbacks

  # Loops over entries, adding the module name of an Ecto Schema
  # operating over the referenced tables to the `schema` key. Errors
  # if a matching schema is not found
  defp pair_schemata(entries) do
    schema_modules = Introspection.ecto_schema_modules()
    # IO.inspect(schema_modules: schema_modules)
    index =
      Enum.reduce(schema_modules, %{}, fn module, acc ->
        schema_reduce(Introspection.ecto_schema_table(module), module, acc)
      end)

    Enum.reduce(entries, [], &pair_schema(&1, Map.get(index, &1.table), &2))
  end

  # Drop an entry where the table does not exist
  defp schema_reduce(nil, _, acc), do: acc
  defp schema_reduce(table, module, acc), do: Map.put(acc, table, module)

  # Error if there was no matching schema, otherwise add it to the entry
  defp pair_schema(_entry, nil, acc), do: acc

  # uncomment the following line if you want to auto-remove defunct tables from your meta table
  # CommonsPub.ReleaseTasks.remove_meta_table(entry.table)
  # throw {:missing_schema, entry.table}
  # end

  defp pair_schema(entry, schema, acc), do: [%{entry | schema: schema} | acc]

  defp populate_table(entries) do
    :ets.new(@table_name, [:named_table])

    # to enable list queries
    all = {:ALL, entries}
    true = :ets.insert(@table_name, all)

    for field <- [:id, :table, :schema] do
      indexed = Enum.map(entries, &{Map.get(&1, field), &1})
      true = :ets.insert(@table_name, indexed)
    end
  end
end
