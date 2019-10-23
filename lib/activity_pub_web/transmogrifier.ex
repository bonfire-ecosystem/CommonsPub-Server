# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPubWeb.Transmogrifier do
  @moduledoc """
  This module normalises outgoing data to conform with AS2/AP specs
  and handles incoming objects and activities
  """

  alias ActivityPub.Actor
  alias ActivityPub.Fetcher
  alias ActivityPub.Object
  alias ActivityPub.Utils
  require Logger

  @doc """
  Translates MN Entity to an AP compatible format
  """
  def prepare_outgoing(%{"type" => "Create", "object" => object_id} = data) do
    object =
      object_id
      |> Object.normalize()
      |> Map.get(:data)
      |> prepare_object

    data =
      data
      |> Map.put("object", object)
      |> Map.merge(Utils.make_json_ld_header())
      |> Map.delete("bcc")

    {:ok, data}
  end

  # TODO hack for mastodon accept and reject type activity formats
  def prepare_outgoing(%{"type" => _type} = data) do
    data =
      data
      |> Map.merge(Utils.make_json_ld_header())

    {:ok, data}
  end

  # We currently do not perform any transformations on objects
  def prepare_object(object), do: object

  # incoming activities

  # TODO
  defp mastodon_follow_hack(_, _), do: {:error, nil}

  defp get_follow_activity(follow_object, followed) do
    with object_id when not is_nil(object_id) <- Utils.get_ap_id(follow_object),
         {_, %Object{} = activity} <- {:activity, Object.get_by_ap_id(object_id)} do
      {:ok, activity}
    else
      # Can't find the activity. This might a Mastodon 2.3 "Accept"
      {:activity, nil} ->
        mastodon_follow_hack(follow_object, followed)

      _ ->
        {:error, nil}
    end
  end

  def handle_incoming(%{"type" => "Create", "object" => object} = data) do
    data = Utils.normalize_params(data)
    {:ok, actor} = Actor.get_by_ap_id(data["actor"])

    params = %{
      to: data["to"],
      object: object,
      actor: actor,
      context: object["conversation"],
      local: false,
      published: data["published"],
      additional:
        Map.take(data, [
          "cc",
          "directMessage",
          "id"
        ])
    }

    ActivityPub.create(params)
  end

  def handle_incoming(
        %{"type" => "Follow", "object" => followed, "actor" => follower, "id" => id} = data
      ) do
    with {:ok, followed} <- Actor.get_by_ap_id(followed),
         {:ok, follower} <- Actor.get_by_ap_id(follower),
         {:ok, activity} <- ActivityPub.follow(follower, followed, id, false) do
      ActivityPub.accept(%{
        to: [follower["id"]],
        actor: followed,
        object: data,
        local: true
      })

      {:ok, activity}
    end
  end

  def handle_incoming(
        %{"type" => "Accept", "object" => follow_object, "actor" => _actor, "id" => _id} = data
      ) do
    with actor <- Fetcher.get_actor(data),
         {:ok, followed} <- Actor.get_by_ap_id(actor),
         {:ok, follow_activity} <- get_follow_activity(follow_object, followed) do
      ActivityPub.accept(%{
        to: follow_activity.data["to"],
        type: "Accept",
        actor: followed,
        object: follow_activity.data["id"],
        local: false
      })
    else
      _e -> :error
    end
  end

  # TODO: add reject

  def handle_incoming(
        %{"type" => "Block", "object" => blocked, "actor" => blocker, "id" => id} = _data
      ) do
    with {:ok, %{local: true} = blocked} <- Actor.get_by_ap_id(blocked),
         {:ok, blocker} <- Actor.get_by_ap_id(blocker),
         {:ok, activity} <- ActivityPub.block(blocker, blocked, id, false) do
      {:ok, activity}
    else
      _e -> :error
    end
  end

  def handle_incoming(
        %{"type" => "Delete", "object" => object_id, "actor" => _actor, "id" => _id} = _data
      ) do
    object_id = Utils.get_ap_id(object_id)

    with {:ok, object} <- Object.get_by_ap_id(object_id),
         {:ok, activity} <- ActivityPub.delete(object, false) do
      {:ok, activity}
    else
      _e -> :error
    end
  end

  def handle_incoming(
        %{
          "type" => "Undo",
          "object" => %{"type" => "Follow", "object" => followed},
          "actor" => follower,
          "id" => id
        } = _data
      ) do
    with {:ok, follower} <- Actor.get_by_ap_id(follower),
         {:ok, followed} <- Actor.get_by_ap_id(followed) do
      ActivityPub.unfollow(follower, followed, id, false)
    else
      _e -> :error
    end
  end

  def handle_incoming(
        %{
          "type" => "Undo",
          "object" => %{"type" => "Block", "object" => blocked},
          "actor" => blocker,
          "id" => id
        } = _data
      ) do
    with {:ok, %{local: true} = blocked} <- Actor.get_by_ap_id(blocked),
         {:ok, blocker} <- Actor.get_by_ap_id(blocker),
         {:ok, activity} <- ActivityPub.unblock(blocker, blocked, id, false) do
      {:ok, activity}
    else
      _e -> :error
    end
  end

  def handle_incoming(data) do
    Logger.info("Unhandled activity. Storing...")

    {:ok, activity, _object} = Utils.insert_full_object(data)
    handle_object(activity)
  end

  @doc """
  Normalises and inserts an incoming AS2 object. Returns Object.
  """
  @collection_types ["Collection", "OrderedCollection", "CollectionPage", "OrderedCollectionPage"]
  def handle_object(%{"type" => type} = data) when type in @collection_types do
    with {:ok, object} <- Utils.prepare_data(data) do
      {:ok, object}
    else
      {:error, e} -> {:error, e}
    end
  end

  def handle_object(data) do
    with {:ok, object} <- Utils.prepare_data(data),
         {:ok, object} <- Object.insert(object) do
      {:ok, object}
    else
      {:error, e} -> {:error, e}
    end
  end
end