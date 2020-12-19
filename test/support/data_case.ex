# SPDX-License-Identifier: AGPL-3.0-only

defmodule CommonsPub.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate
  alias Bonfire.Fail.Error

  using do
    quote do
      alias CommonsPub.Repo
      import CommonsPub.DataCase
      use Bamboo.Test
    end
  end

  setup tags do
    Cachex.clear(:ap_actor_cache)
    Cachex.clear(:ap_object_cache)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(CommonsPub.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(CommonsPub.Repo, {:shared, self()})
    end

    :ok
  end

  @doc """
  A helper that transform changeset errors to a map of messages.

      changeset = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  @doc "true if the first was updated more recently than the second"
  def was_updated_since?(new_thing, old_thing) do
    DateTime.compare(new_thing.updated_at, old_thing.updated_at) == :gt
  end

  @doc "Removes the timestamps from a thing"
  def timeless(thing), do: Map.drop(thing, [:inserted_at, :updated_at, :deleted_at])

  @doc "Returns a copy of the loaded ecto model which is marked as deleted"
  def deleted(%{__meta__: %{state: :loaded} = meta} = thing) do
    meta2 = Map.put(meta, :state, :deleted)
    Map.put(thing, :__meta__, meta2)
  end

  @doc "Returns true if the provided is an that was stale"
  def was_already_deleted?(%Error{message: "has already been deleted"}),
    do: true

  def was_already_deleted?(_), do: false
end
