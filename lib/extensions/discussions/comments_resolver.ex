# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Web.GraphQL.CommentsResolver do
  alias CommonsPub.{GraphQL, Repo, Threads}
  # alias CommonsPub.Collections.Collection
  # alias CommonsPub.Communities.Community
  # alias CommonsPub.Flags.Flag
  alias Bonfire.GraphQL
  alias Bonfire.GraphQL.{FetchFields, FetchPage, ResolveFields, ResolvePages}
  # alias Bonfire.Common.Pointers
  # alias CommonsPub.Resources.Resource
  alias CommonsPub.Threads.{Comment, Comments, Thread}

  def comment(%{comment_id: id}, %{context: %{current_user: user}}) do
    Comments.one(id: id, user: user)
  end

  def comments_edge(%Thread{id: id}, %{} = page_opts, info) do
    ResolvePages.run(%ResolvePages{
      module: __MODULE__,
      fetcher: :fetch_comments_edge,
      context: id,
      page_opts: page_opts,
      info: info
    })
  end

  # def fetch_comments_edge({page_opts, info}, ids) do
  #   user = GraphQL.current_user(info)
  #   FetchPages.run(
  #     %FetchPages{
  #       queries: CommentsQueries,
  #       query: Comment,
  #       group_fn: &(&1.thread_id),
  #       page_opts: page_opts,
  #       base_filters: [user: user, thread_id: ids],
  #       data_filters: [order: :timeline_asc],
  #       count_filters: [group_count: :thread_id],
  #     }
  #   )
  # end

  def fetch_comments_edge(page_opts, info, id) do
    user = GraphQL.current_user(info)

    FetchPage.run(%FetchPage{
      queries: Threads.CommentsQueries,
      query: Comment,
      page_opts: page_opts,
      base_filters: [user: user, thread: id],
      data_filters: [page: [asc: [created: page_opts]]]
    })
  end

  def in_reply_to_edge(%Comment{reply_to_id: nil}, _, _info), do: {:ok, nil}

  def in_reply_to_edge(%Comment{reply_to_id: id}, _, info) do
    ResolveFields.run(%ResolveFields{
      module: __MODULE__,
      fetcher: :fetch_in_reply_to_edge,
      context: id,
      info: info
    })
  end

  def fetch_in_reply_to_edge(info, ids) do
    user = GraphQL.current_user(info)

    FetchFields.run(%FetchFields{
      queries: Threads.CommentsQueries,
      query: Comment,
      group_fn: & &1.id,
      filters: [id: ids, user: user]
    })
  end

  def thread_edge(%Comment{thread: %Thread{} = thread}, _, _info), do: {:ok, thread}

  def thread_edge(%Comment{thread_id: id}, _, info) do
    ResolveFields.run(%ResolveFields{
      module: __MODULE__,
      fetcher: :fetch_thread_edge,
      context: id,
      info: info
    })
  end

  def fetch_thread_edge(info, ids) do
    user = GraphQL.current_user(info)

    FetchFields.run(%FetchFields{
      queries: Threads.Queries,
      query: Thread,
      group_fn: & &1.id,
      filters: [id: ids, user: user]
    })
  end

  ## mutations

  # defp validate_thread_context(%Collection{}), do: :ok
  # defp validate_thread_context(%Community{}), do: :ok
  # defp validate_thread_context(%Flag{}), do: :ok
  # defp validate_thread_context(%Resource{}), do: :ok
  # defp validate_thread_context(_), do: GraphQL.not_permitted("create")

  def create_reply(%{thread_id: thread_id, in_reply_to_id: reply_to, comment: attrs}, info)
      when not is_nil(reply_to) do
    with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info) do
      Repo.transact_with(fn ->
        with {:ok, thread} <-
               Threads.one(hidden: false, deleted: false, published: true, id: thread_id),
             {:ok, parent} <-
               Comments.one(hidden: false, deleted: false, published: true, id: reply_to),
             attrs = Map.put(attrs, :is_local, true) do
          Comments.create_reply(user, thread, parent, attrs)
        end
      end)
    end
  end

  def create_reply(%{thread_id: thread_id, comment: attrs}, info) do
    with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info) do
      Repo.transact_with(fn ->
        with {:ok, thread} <-
               Threads.one(hidden: false, deleted: false, published: true, id: thread_id),
             attrs = Map.put(attrs, :is_local, true) do
          Comments.create_reply(user, thread, attrs)
        end
      end)
    end
  end

  def update(%{comment_id: comment_id, comment: changes}, info) do
    with {:ok, user} <- GraphQL.current_user(info),
         {:ok, comment} <- Comments.one(id: comment_id) do
      cond do
        user.is_local_admin ->
          Comments.update(user, comment, changes)

        comment.creator_id == user.id ->
          Comments.update(user, comment, changes)

        true ->
          GraphQL.not_permitted("update")
      end
    end
  end

  def last_activity_edge(_, _, _info) do
    {:ok, DateTime.utc_now()}
  end
end
