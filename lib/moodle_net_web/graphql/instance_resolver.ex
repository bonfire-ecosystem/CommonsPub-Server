# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.InstanceResolver do

  alias MoodleNet.{Features, Instance}
  alias MoodleNet.Collections.Collection
  alias MoodleNet.Communities.Community

  def instance(_, _info) do
    {:ok, %{hostname: Instance.hostname(), description: Instance.description()}}
  end

  def featured_communities(_, _args, _info) do
    Features.page(
      &(&1.id),
      [join: :context, table: Community],
      [order: :timeline_desc, preload: :context],
      []
    )
  end

  def featured_collections(_, _args, _info) do
    Features.page(
      &(&1.id),
      [join: :context, table: Collection],
      [order: :timeline_desc, preload: :context],
      []
    )
  end

  def outbox_edge(_, _, _info) do
    Instance.outbox()
  end

end