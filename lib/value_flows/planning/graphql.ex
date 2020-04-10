# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Planning.GraphQL do
  alias MoodleNet.{
    Activities,
    Communities,
    GraphQL,
    Repo,
  }
  alias MoodleNet.GraphQL.{
    Flow,
    FieldsFlow,
    PageFlow,
    PagesFlow,
    ResolveField,
    ResolvePage,
    ResolvePages,
    ResolveRootPage,
  }
  # alias MoodleNet.Resources.Resource
  alias MoodleNet.Common.Enums
  alias MoodleNetWeb.GraphQL.CommunitiesResolver

  # alias Geolocation
  # alias Geolocation.Geolocations
  # alias Geolocation.Queries

  # SDL schema import

  use Absinthe.Schema.Notation
  alias MoodleNetWeb.GraphQL.{CommonResolver}
  require Logger

  import_sdl path: "lib/geolocation/geolocation.gql"

  ## resolvers

  def intent(%{id: id}, info) do
    ResolveField.run(
      %ResolveField{
        module: __MODULE__,
        fetcher: :fetch_intent,
        context: id,
        info: info,
      }
    )
  end

  def all_intents(page_opts, info) do
    ResolveRootPage.run(
      %ResolveRootPage{
        module: __MODULE__,
        fetcher: :fetch_intents,
        page_opts: page_opts,
        info: info,
        cursor_validators: [&(is_integer(&1) and &1 >= 0), &Ecto.ULID.cast/1], # popularity
      }
    )
  end

  ## fetchers

  def fetch_intent(info, id) do
    Intents.one(
      user: GraphQL.current_user(info),
      id: id,
      preload: :actor
    )
  end

  def fetch_intents(page_opts, info) do
    PageFlow.run(
      %PageFlow{
        queries: Queries,
        query: Intent,
        cursor_fn: Intents.cursor(:followers),
        page_opts: page_opts,
        base_filters: [user: GraphQL.current_user(info)],
        data_filters: [page: [desc: [followers: page_opts]]],
      }
    )
  end


  def community_edge(%Intent{community_id: id}, _, info) do
    Flow.fields __MODULE__, :fetch_community_edge, id, info
  end

  def fetch_community_edge(_, ids) do
    {:ok, fields} = Communities.fields(&(&1.id), [:default, id: ids])
    fields
  end

  def last_activity_edge(_, _, _info) do
    {:ok, DateTime.utc_now()}
  end

  def outbox_edge(%Intent{outbox_id: id}, page_opts, info) do
    opts = %{default_limit: 10}
    Flow.pages(__MODULE__, :fetch_outbox_edge, page_opts, info, id, info, opts)
  end

  def fetch_outbox_edge({page_opts, info}, id) do
    user = info.context.current_user
    {:ok, box} = Activities.page(
      &(&1.id),
      &(&1.id),
      page_opts,
      feed: id,
      table: default_outbox_query_contexts()
    )
    box
  end

  def fetch_outbox_edge(page_opts, info, id) do
    user = info.context.current_user
    Activities.page(
      &(&1.id),
      page_opts,
      feed: id,
      table: default_outbox_query_contexts()
    )
  end

  defp default_outbox_query_contexts() do
    Application.fetch_env!(:moodle_net, Intents)
    |> Keyword.fetch!(:default_outbox_query_contexts)
  end

  ## finally the mutations...

  def create_intent(%{intent: attrs, in_scope_of_community_id: id}, info) do
    Repo.transact_with(fn ->
      with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info),
           {:ok, community} <- CommunitiesResolver.community(%{community_id: id}, info) do
        attrs = Map.merge(attrs, %{is_public: true})
        Intents.create(user, community, attrs)
      end
    end)
  end

  def update_intent(%{intent: changes, intent_id: id}, info) do
    Repo.transact_with(fn ->
      with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info),
           {:ok, intent} <- intent(%{intent_id: id}, info) do
        intent = Repo.preload(intent, :community)
        cond do
          user.local_user.is_instance_admin ->
        Intents.update(intent, changes)

          intent.creator_id == user.id ->
        Intents.update(intent, changes)

          intent.community.creator_id == user.id ->
        Intents.update(intent, changes)

          true -> GraphQL.not_permitted("update")
        end
      end
    end)
  end


end
