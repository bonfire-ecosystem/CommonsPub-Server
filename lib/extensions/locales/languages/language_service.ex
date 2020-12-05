# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Locales.Language.Service do
  @moduledoc """
  An ets-based cache that allows lookup up Language objects by:

  * Database ID (string)

  On startup:
  * The database is queried for a list of languages
  * The data is inserted into an ets table owned by the process

  During operation, lookup requests will hit ets directly - this
  service exists solely to own the table and fit into the OTP
  supervision hierarchy neatly.
  """

  alias CommonsPub.Locales.{Language}

  alias CommonsPub.Repo

  # import Ecto.Query, only: [select: 3]

  use GenServer

  @init_query_name __MODULE__
  @service_name __MODULE__
  @table_name __MODULE__.Cache

  # public api

  @spec start_link() :: GenServer.on_start()
  @doc "Starts up the service registering it locally under this module's name"
  def start_link(),
    do: GenServer.start_link(__MODULE__, name: @service_name)

  @doc "Lists all languages we know"
  @spec list_all() :: [Language.t()]
  def list_all() do
    case :ets.lookup(@table_name, :ALL) do
      [{_, r}] -> r
      _ -> []
    end
  end

  @spec lookup(id :: binary()) ::
          {:ok, Language.t()} | {:error, Language.Error.NotFound.t()}
  @doc "Look up a Language by iso2 code"
  def lookup(key) when is_binary(key),
    do: lookup_result(key, :ets.lookup(@table_name, key))

  defp lookup_result(_key, []), do: {:error, Language.Error.NotFound.new()}
  defp lookup_result(_, [{_, v}]), do: {:ok, v}

  @spec lookup!(id :: binary) :: Language.t()
  @doc "Look up a Language by iso2 code, throw Language.Error.NotFound if not found"
  def lookup!(key) do
    case lookup(key) do
      {:ok, v} -> v
      {:error, reason} -> throw(reason)
    end
  end

  # @spec lookup_id(id :: binary) :: {:ok, binary} | {:error, Language.Error.NotFound.t()}
  # @doc "Look up a language id by iso2 code"
  # def lookup_id(key) do
  #   with {:ok, val} <- lookup(key), do: {:ok, val.id}
  # end

  # @spec lookup_id!(id :: binary) :: binary
  # @doc "Look up a language id by iso2 code, throw Language.Error.NotFound if not found"
  # def lookup_id!(key) do
  #   case lookup_id(key) do
  #     {:ok, v} -> v
  #     {:error, reason} -> throw(reason)
  #   end
  # end

  # callbacks

  @doc false
  def init(_) do
    try do
      Language
      |> Repo.all(telemetry_event: @init_query_name)
      |> populate_languages()

      {:ok, []}
    rescue
      e ->
        IO.inspect("INFO: LanguageService could not init because:")
        IO.inspect(e)
        {:ok, []}
    end
  end

  defp populate_languages(entries) do
    :ets.new(@table_name, [:named_table])
    # to enable list queries
    all = {:ALL, entries}

    indexed =
      Enum.flat_map(entries, fn lang ->
        [{lang.id, lang}, {lang.iso639_1, lang}]
      end)

    true = :ets.insert(@table_name, [all | indexed])
  end

  # import Ecto.Query, only: [from: 2]

  # defp q() do
  #   from l in Language, order_by: [asc: l.id]
  # end
end
