# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Profiles.Queries do
  # alias CommonsPub.Users
  alias CommonsPub.Profiles.Profile
  # alias CommonsPub.Follows.{Follow, FollowerCount}
  alias CommonsPub.Users.User
  import CommonsPub.Repo.Query, only: [match_admin: 0]
  import Ecto.Query

  def query(Profile) do
    from(c in CommonsPub.Profiles.Profile, as: :profile)
  end

  def query(:count) do
    from(c in CommonsPub.Profiles.Profile, as: :profile)
  end

  def query(q, filters), do: filter(query(q), filters)

  def queries(query, _page_opts, base_filters, data_filters, count_filters) do
    base_q = query(query, base_filters)
    data_q = filter(base_q, data_filters)
    count_q = filter(base_q, count_filters)
    {data_q, count_q}
  end

  def join_to(q, spec, join_qualifier \\ :left)

  def join_to(q, specs, jq) when is_list(specs) do
    Enum.reduce(specs, q, &join_to(&2, &1, jq))
  end

  ### filter/2

  ## by many

  def filter(q, filters) when is_list(filters) do
    Enum.reduce(filters, q, &filter(&2, &1))
  end

  ## by preset

  def filter(q, :default) do
    filter(q, [:deleted])
  end

  ## by join

  def filter(q, {:join, {join, qual}}), do: join_to(q, join, qual)
  def filter(q, {:join, join}), do: join_to(q, join)

  ## by user

  def filter(q, {:user, match_admin()}), do: q

  # def filter(q, {:user, %User{id: id} = user}) do
  #   q
  #   |> join_to(follow: id)
  #   |> where([profile: o, follow: f], not is_nil(o.published_at) or not is_nil(f.id))
  # end

  def filter(q, {:user, %User{id: _id} = _user}) do
    q
    |> where([profile: o], not is_nil(o.published_at))
  end

  def filter(q, {:user, nil}) do
    filter(q, ~w(deleted disabled private)a)
  end

  ## by status

  def filter(q, :deleted) do
    where(q, [profile: o], is_nil(o.deleted_at))
  end

  def filter(q, :disabled) do
    where(q, [profile: o], is_nil(o.disabled_at))
  end

  def filter(q, :private) do
    where(q, [profile: o], not is_nil(o.published_at))
  end

  ## by field values

  def filter(q, {:id, id}) when is_binary(id) do
    where(q, [profile: c], c.id == ^id)
  end

  def filter(q, {:id, ids}) when is_list(ids) do
    where(q, [profile: c], c.id in ^ids)
  end

  def filter(q, {:username, username}) when is_binary(username) do
    where(q, [character: a], a.preferred_username == ^username)
  end

  def filter(q, {:username, usernames}) when is_list(usernames) do
    where(q, [character: a], a.preferred_username in ^usernames)
  end

  ## by ordering

  def filter(q, {:order, :followers_desc}) do
    filter(q, order: [desc: :followers])
  end

  def filter(q, {:order, [desc: :followers]}) do
    order_by(q, [profile: c, follower_count: fc],
      desc: coalesce(fc.count, 0),
      desc: c.id
    )
  end

  # grouping and counting

  def filter(q, {:group_count, key}) when is_atom(key) do
    filter(q, group: key, count: key)
  end

  def filter(q, {:group, key}) when is_atom(key) do
    group_by(q, [profile: c], field(c, ^key))
  end

  def filter(q, {:count, key}) when is_atom(key) do
    select(q, [profile: c], {field(c, ^key), count(c.id)})
  end

  # pagination

  def filter(q, {:limit, limit}) do
    limit(q, ^limit)
  end

  def filter(q, {:paginate_id, %{after: a, limit: limit}}) do
    limit = limit + 2

    q
    |> where([profile: c], c.id >= ^a)
    |> limit(^limit)
  end

  def filter(q, {:paginate_id, %{before: b, limit: limit}}) do
    q
    |> where([profile: c], c.id <= ^b)
    |> filter(limit: limit + 2)
  end

  def filter(q, {:paginate_id, %{limit: limit}}) do
    filter(q, limit: limit + 1)
  end

  def filter(q, {:page, [desc: [followers: page_opts]]}) do
    q
    |> filter(join: :follower_count, order: [desc: :followers])
    |> page(page_opts, desc: :followers)
    |> select(
      [profile: c, character: a, follower_count: fc],
      %{c | follower_count: coalesce(fc.count, 0), character: a}
    )
  end

  defp page(q, %{after: cursor, limit: limit}, desc: :followers) do
    filter(q, cursor: [followers: {:lte, cursor}], limit: limit + 2)
  end

  defp page(q, %{before: cursor, limit: limit}, desc: :followers) do
    filter(q, cursor: [followers: {:gte, cursor}], limit: limit + 2)
  end

  defp page(q, %{limit: limit}, _), do: filter(q, limit: limit + 1)
end
