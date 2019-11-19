# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.UsersResolver do
  @moduledoc """
  Performs the GraphQL User queries.
  """
  alias Absinthe.Resolution
  alias MoodleNetWeb.GraphQL
  alias MoodleNetWeb.GraphQL.Errors
  alias MoodleNet.{Access, Actors, Collections, Common, Communities, Fake, GraphQL, OAuth, Repo, Users}
  alias MoodleNet.Common.{
    AlreadyFlaggedError,
    AlreadyFollowingError,
    NotFlaggableError,
    NotFoundError,
    NotPermittedError,
  }
  alias MoodleNet.Users.{Me, User}

  def username_available(%{username: username}, _info) do
    {:ok, Actors.is_username_available?(username)}
  end
  def me(_, info) do
    with {:ok, current_user} <- GraphQL.current_user(info) do
      {:ok, Me.new(Users.preload_actor(current_user))}
    end
  end

  def me(%{token: _, me: me}, _, _), do: {:ok, me}

  def user(%{user_id: id}, info), do: Users.fetch(id)
  # def user(%{preferred_username: name}, info), do: Users.fetch_by_username(name)

  def user(%Me{}=me, _, info), do: {:ok, me.user}

  # def user(%Activity{}=activity, _, info)
  # def user(%Like{}=like, _, info)
  # def user(%Flag{}=flag, _, info)
  # def user(%Block{}=flag, _, info)
  # def user(%Follow{}=flag, _, info)
  # def user(%Tagging{}=tagging, _, info)

  def create_user(%{user: attrs}, info) do
    extra = %{is_public: true}
    with :ok <- GraphQL.guest_only(info),
         {:ok, user} <- Users.register(Map.merge(attrs, extra)) do
      {:ok, Me.new(user)}
    end
  end

  def update_profile(%{profile: attrs}, info) do
    with {:ok, user} <- GraphQL.current_user(info),
         {:ok, user} <- Users.update(user, attrs) do
      {:ok, Me.new(user)}
    end
  end

  def delete(%{i_am_sure: true}, info) do
    with {:ok, user} <- GraphQL.current_user(info),
         {:ok, _} <- Users.soft_delete(user) do
      {:ok, true}
    end
  end
  def delete(%{i_am_sure: false}, info) do
    {:error, "Now is not the time to have second thoughts."}
  end

  def create_session(%{email: email, password: password}, info) do
    case Users.fetch_by_email(email) do
      {:ok, user} ->
        with {:ok, token} <- Access.create_token(user, password) do
          {:ok, %{token: token.id, me: Me.new(user)}}
        end
      _ ->
	Argon2.no_user_verify([])
	GraphQL.invalid_credential()
    end
  end

  def delete_session(_, info) do
    with {:ok, user} <- GraphQL.current_user(info),
         {:ok, token} <- Access.fetch_token(user),
         {:ok, token} <- Access.hard_delete(token) do
      {:ok, true}
    end
  end

  def reset_password_request(%{email: email}, info) do
    with :ok <- GraphQL.guest_only(info),
    	 {:ok, user} <- Users.fetch_by_email(email),
         {:ok, token} <- Users.request_password_reset(user) do
      {:ok, true}
    end
 end

  def reset_password(%{token: token, password: password}, info) do
    with :ok <- GraphQL.guest_only(info),
    	 {:ok, user} <- Users.claim_password_reset(token, password),
         {:ok, token} <- Access.unsafe_put_token(user) do
      {:ok, %{token: token.id, me: Me.new(user)}}
    end
  end

  def confirm_email(%{token: token}, info) do
    Repo.transact_with(fn ->
      with {:ok, user} <- Users.claim_email_confirm_token(token),
           {:ok, token} <- Access.unsafe_put_token(user) do
        {:ok, %{token: token.id, me: Me.new(user)}}
      end
    end)
  end

  def email(me, _, _), do: {:ok, me.user.local_user.email}
  def wants_email_digest(me, _, _), do: {:ok, me.user.local_user.wants_email_digest}
  def wants_notifications(me, _, _), do: {:ok, me.user.local_user.wants_notifications}
  def is_confirmed(me, _, _), do: {:ok, not is_nil(me.user.local_user.confirmed_at)}
  def is_instance_admin(me, _, _), do: {:ok, me.user.local_user.is_instance_admin}

  def canonical_url(user, _, _), do: {:ok, Fake.website()} # {:ok, user.actor.canonical_url}
  def preferred_username(user, _, _), do: {:ok, user.actor.preferred_username}
  def is_local(user, _, _), do: {:ok, is_nil(user.actor.peer_id)}
  def is_public(user, _, _), do: {:ok, not is_nil(user.published_at)}
  def is_disabled(user, _, _), do: {:ok, not is_nil(user.disabled_at)}
  def is_deleted(user, _, _), do: {:ok, not is_nil(user.deleted_at)}

  def inbox(%User{}=user, params, info) do
    # with {:ok, current_user} <- GraphQL.current_user(info) do
    #   if user.id == current_user.id do
    #     Repo.transact_with(fn ->
    #       activities = Users.inbox(current_user)
    #       count = Users.count_for_inbox(current_user)
    #       page_info = Common.page_info(activities)
    #       {:ok, %{page_info: page_info, total_count: count, edges: activities}}
    #     end)
    #   else
    # 	GraphQL.not_permitted()
    #   end
    # end
    {:ok, GraphQL.edge_list([],0)}
  end

  def outbox(user, params, info) do
    # Repo.transact_with(fn ->
    #   activities =
    #     Users.outbox(user)
    #     |> Enum.map(fn box -> %{cursor: box.id, node: box.activity} end)
    #   count = Users.count_for_outbox(user)
    #   page_info = Common.page_info(activities)
    #   {:ok, %{page_info: page_info, total_count: count, edges: activities}}
    # end)
    {:ok, GraphQL.edge_list([],0)}
  end

  def followed_communities(%User{}=user,_,info) do
    Repo.transact_with(fn ->
      comms =
	Common.list_followed_communities(user)
        |> Enum.map(fn {f,c} -> %{cursor: f.id, node: %{follow: f, community: Communities.preload(c)}} end)
      count = Common.count_for_list_followed_communities(user)
      page_info = Common.page_info(comms, &(&1.node.follow.id))
      {:ok, %{page_info: page_info, total_count: count, edges: comms}}
    end)
  end

  def follow(%{follow: follow}, _, _), do: {:ok, follow}
  def community(%{community: community}, _, _), do: {:ok, community}

  def followed_collections(%User{}=user,_,info) do
    Repo.transact_with(fn ->
      colls =
	Common.list_followed_collections(user)
        |> Enum.map(fn {f,c} ->
	  %{cursor: f.id, node: %{follow: f, collection: Collections.preload(c)}}
        end)
      count = Common.count_for_list_followed_collections(user)
      page_info = Common.page_info(colls, &(&1.cursor))
      {:ok, %{page_info: page_info, total_count: count, edges: colls}}
    end)
  end

  def followed_users(_,_,info) do
  end

  def creator(parent,_,info) do
    Users.fetch(parent.creator_id)
  end

  def last_activity(parent,_,info), do: {:ok, Fake.past_datetime()}
    # case Repo.preload(parent, :last_activity).last_activity do
    # end
    
  # end

  
end
