# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Blocks do
  alias Ecto.Changeset
  alias MoodleNet.{Common, Repo}
  alias MoodleNet.Blocks.{Block, Queries}
  alias MoodleNet.Users.User
  
  @spec find(User.t(), %{id: binary}) :: {:ok, Block.t()} | {:error, NotFoundError.t()}
  def find(%User{} = blocker, blocked) do
    Repo.single(find_q(blocker.id, blocked.id))
  end

  defp find_q(blocker_id, blocked_id) do
    Queries.query(Block, [deleted: false, creator: blocker_id, context: blocked_id])
  end

  @spec create(User.t(), any, map) :: {:ok, Block.t()} | {:error, Changeset.t()}
  def create(%User{} = blocker, blocked, fields) do
    Repo.insert(Block.create_changeset(blocker, blocked, fields))
  end

  @spec update(Block.t(), map) :: {:ok, Block.t()} | {:error, Changeset.t()}
  def update(%Block{} = block, fields) do
    Repo.update(Block.update_changeset(block, fields))
  end

  @spec delete(Block.t()) :: {:ok, Block.t()} | {:error, Changeset.t()}
  def delete(%Block{} = block), do: Common.soft_delete(block)

  def update_by(filters, updates), do: Repo.update_all(Queries.query(Block, filters), updates)

end
