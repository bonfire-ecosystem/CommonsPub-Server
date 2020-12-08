# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Meta.TableServiceTest do
  use ExUnit.Case, async: true

  import ExUnit.Assertions
  import Bonfire.Repo.Introspection, only: [ecto_schema_table: 1]
  alias CommonsPub.Repo



  alias Pointers.Table

  alias CommonsPub.Access.{RegisterEmailAccess, RegisterEmailDomainAccess}
  alias CommonsPub.Activities.Activity
  alias CommonsPub.Communities.Community
  alias CommonsPub.Collections.Collection
  alias CommonsPub.Resources.Resource
  alias CommonsPub.Threads.{Comment, Thread}

  alias CommonsPub.Blocks.Block
  alias CommonsPub.Flags.Flag
  alias CommonsPub.Follows.Follow
  alias CommonsPub.Features.Feature
  alias CommonsPub.Likes.Like
  alias CommonsPub.Feeds.Feed
  alias CommonsPub.Peers.Peer
  alias CommonsPub.Users.User
  alias CommonsPub.Locales.{Country, Language}

  @known_schemas [
    # Table,
    Feature,
    Feed,
    Peer,
    User,
    Community,
    Collection,
    Resource,
    Comment,
    Thread,
    Flag,
    Follow,
    Like,
    # Country,
    # Language,
    RegisterEmailAccess,
    RegisterEmailDomainAccess,
    Block,
    Activity
  ]
  @known_tables Enum.map(@known_schemas, &ecto_schema_table/1)
  @table_schemas Map.new(Enum.zip(@known_tables, @known_schemas))
  @expected_table_names Enum.sort(@known_tables)

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(CommonsPub.Repo)
    {:ok, %{}}
  end

  test "is fetching from good source data" do
    in_db = Enum.map(Repo.all(Table), & &1.table)
    for table <- @expected_table_names, do: assert(table in in_db)
  end

  @bad_table_names ["fizz", "buzz bazz"]

  test "returns results consistent with the source data" do
    tables = Repo.all(Table)
    # assert Enum.count(tables) == Enum.count(@expected_table_names)
    # Every db entry must match up to our module metadata
    for t <- tables do
      assert %{id: id, table: table} = t

      if schema = Map.get(@table_schemas, table) do
        # assert schema in @known_schemas
        t2 = %{t | schema: schema}
        # There are 3 valid keys, 3 pairs of functions to check
        for key <- [schema, table, id] do
          assert {:ok, t2} == Pointers.Tables.table(key)
          assert {:ok, id} == Pointers.Tables.id(key)
          assert {:ok, schema} == Pointers.Tables.schema(key)
          assert t2 == Pointers.Tables.table!(key)
          assert id == Pointers.Tables.id!(key)
          assert schema == Pointers.Tables.schema!(key)
        end
      end
    end

    for t <- @bad_table_names do
      assert {:error, %Pointers.NotFound{}} == Pointers.Tables.table(t)
      assert %Pointers.NotFound{} == catch_throw(Pointers.Tables.table!(t))
    end
  end
end
