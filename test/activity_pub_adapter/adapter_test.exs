defmodule CommonsPub.ActivityPub.AdapterTest do
  import ActivityPub.Factory
  import CommonsPub.Test.Faking
  alias CommonsPub.ActivityPub.Adapter

  use CommonsPub.DataCase


  describe "fetching local actors by id" do
    test "users" do
      user = fake_user!()
      {:ok, actor} = ActivityPub.Actor.get_by_local_id(user.id)
      assert actor.data["type"] == "Person"
      assert actor.username == user.character.preferred_username
    end

    test "communities" do
      user = fake_user!()
      community = fake_community!(user)
      {:ok, actor} = ActivityPub.Actor.get_by_local_id(community.id)
      assert actor.data["type"] == "MN:Community"
      assert actor.username == community.character.preferred_username
      assert actor.data["attributedTo"]
    end

    test "collections" do
      user = fake_user!()
      community = fake_community!(user)
      collection = fake_collection!(user, community)
      {:ok, actor} = ActivityPub.Actor.get_by_local_id(collection.id)
      assert actor.data["type"] == "MN:Collection"
      assert actor.username == collection.character.preferred_username
      assert actor.data["attributedTo"]
      assert actor.data["context"]
    end
  end

  describe "fetching local actors by username" do
    test "users" do
      user = fake_user!()
      {:ok, actor} = ActivityPub.Actor.get_by_username(user.character.preferred_username)
      assert actor.data["type"] == "Person"
      assert actor.username == user.character.preferred_username
    end

    test "communities" do
      user = fake_user!()
      community = fake_community!(user)
      {:ok, actor} = ActivityPub.Actor.get_by_username(community.character.preferred_username)
      assert actor.data["type"] == "MN:Community"
      assert actor.username == community.character.preferred_username
      assert actor.data["attributedTo"]
    end

    test "collections" do
      user = fake_user!()
      community = fake_community!(user)
      collection = fake_collection!(user, community)
      # IO.inspect(collection)
      {:ok, actor} = ActivityPub.Actor.get_by_username(collection.character.preferred_username)
      assert actor.data["type"] == "MN:Collection"
      assert actor.username == collection.character.preferred_username
      assert actor.data["attributedTo"]
      assert actor.data["context"]
    end
  end

  describe "creating remote actors" do
    test "create remote actor with an icon" do
      actor =
        insert(:actor, %{
          data: %{
            "icon" =>
              "https://kawen.space/media/39fb9c0661e7de08b69163fee0eb99dee5fa399f2f75d695667cabfd9281a019.png?name=MKIOQWLTKDFA.png"
          }
        })

      host = URI.parse(actor.data["id"]).host
      username = actor.data["preferredUsername"] <> "@" <> host

      assert {:ok, created_actor} = Adapter.create_remote_actor(actor.data, username)
      assert created_actor.character.preferred_username == username
      created_actor = CommonsPub.Repo.preload(created_actor, icon: [:content_mirror])

      assert created_actor.icon.content_mirror.url ==
               "https://kawen.space/media/39fb9c0661e7de08b69163fee0eb99dee5fa399f2f75d695667cabfd9281a019.png?name=MKIOQWLTKDFA.png"
    end

    test "crete remote actor with blank name" do
      actor = insert(:actor)
      host = URI.parse(actor.data["id"]).host
      username = actor.data["preferredUsername"] <> "@" <> host
      data = Map.put(actor.data, "name", "")

      assert {:ok, created_actor} = Adapter.create_remote_actor(data, username)
      assert created_actor.character.preferred_username == username
    end

    test "pointer insertion into AP table works" do
      actor = insert(:actor)
      host = URI.parse(actor.data["id"]).host
      username = actor.data["preferredUsername"] <> "@" <> host

      assert {:ok, created_actor} = Adapter.create_remote_actor(actor.data, username)

      assert %ActivityPub.Object{} =
               object = ActivityPub.Object.get_by_pointer_id(created_actor.id)

      assert {:ok, %Pointers.Pointer{}} = CommonsPub.Meta.Pointers.one(id: object.pointer_id)
    end
  end

  describe "handle activity" do
    test "comment on a local actor" do
      actor = actor()
      commented_actor = fake_user!()
      {:ok, ap_commented_actor} = ActivityPub.Actor.get_by_local_id(commented_actor.id)
      note = insert(:note, %{actor: actor, data: %{"context" => ap_commented_actor.data["id"]}})
      note_activity = insert(:note_activity, %{note: note})

      assert :ok = Adapter.perform(:handle_activity, note_activity)
    end

    test "reply to a comment" do
      actor = fake_user!()
      community = fake_user!() |> fake_community!()
      {:ok, thread} = CommonsPub.Threads.create(actor, %{is_local: true}, community)

      {:ok, comment} =
        CommonsPub.Threads.Comments.create(actor, thread, %{is_local: true, content: "hi"})

      {:ok, activity} = CommonsPub.ActivityPub.Publisher.publish("create", comment)
      reply_actor = actor()

      object = %{
        "inReplyTo" => activity.object.data["id"],
        "type" => "Note",
        "actor" => reply_actor.ap_id,
        "content" => "hi"
      }

      params = %{
        actor: reply_actor,
        to: ["https://www.w3.org/ns/activitystreams#Public"],
        object: object,
        context: ActivityPub.Utils.generate_context_id(),
        local: false
      }

      {:ok, _activity} = ActivityPub.create(params)
      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
    end

    test "resource" do
      actor = actor()
      collection = collection()

      object = %{
        "name" => "resource",
        "url" => "http://releases.ubuntu.com/19.10/ubuntu-19.10-desktop-amd64.iso.torrent",
        "actor" => actor.ap_id,
        "attributedTo" => actor.ap_id,
        "context" => collection.ap_id,
        "type" => "Document",
        "tag" => "GPL-v3",
        "summary" => "I use arch btw",
        "icon" => "https://icon.store/picture.png",
        "author" => %{
          "name" => "Author McAuthorface",
          "type" => "Person"
        }
      }

      params = %{
        actor: actor,
        to: ["https://www.w3.org/ns/activitystreams#Public"],
        object: object,
        context: collection.ap_id,
        additional: %{
          "cc" => [collection.data["followers"], actor.data["followers"]]
        },
        local: false
      }

      {:ok, activity} = ActivityPub.create(params)
      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)

      assert {:ok, _} =
               CommonsPub.Repo.fetch_by(CommonsPub.Resources.Resource, %{
                 canonical_url: activity.object.data["id"]
               })
    end

    test "follows" do
      follower = actor()
      followed = fake_user!() |> fake_community!()
      {:ok, ap_followed} = ActivityPub.Actor.get_by_local_id(followed.id)
      {:ok, _} = ActivityPub.follow(follower, ap_followed, nil, false)
      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
      {:ok, follower} = CommonsPub.ActivityPub.Adapter.get_actor_by_ap_id(follower.ap_id)
      assert {:ok, _} = CommonsPub.Follows.one(creator: follower.id, context: followed.id)
    end

    test "unfollows" do
      follower = actor()
      followed = fake_user!() |> fake_community!()
      {:ok, ap_followed} = ActivityPub.Actor.get_by_local_id(followed.id)
      {:ok, _} = ActivityPub.follow(follower, ap_followed, nil, false)
      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
      {:ok, _} = ActivityPub.unfollow(follower, ap_followed, nil, false)
      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
      {:ok, follower} = CommonsPub.ActivityPub.Adapter.get_actor_by_ap_id(follower.ap_id)

      assert {:error, _} =
               CommonsPub.Follows.one(deleted: false, creator: follower.id, context: followed.id)
    end

    test "blocks" do
      blocker = actor()
      blocked = fake_user!() |> fake_community!()
      {:ok, ap_blocked} = ActivityPub.Actor.get_by_local_id(blocked.id)
      {:ok, _} = ActivityPub.block(blocker, ap_blocked, nil, false)
      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
      {:ok, blocker} = CommonsPub.ActivityPub.Adapter.get_raw_actor_by_ap_id(blocker.ap_id)
      assert {:ok, _} = CommonsPub.Blocks.find(blocker, blocked)
    end

    test "unblocks" do
      blocker = actor()
      blocked = fake_user!() |> fake_community!()
      {:ok, ap_blocked} = ActivityPub.Actor.get_by_local_id(blocked.id)
      {:ok, _} = ActivityPub.block(blocker, ap_blocked, nil, false)
      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
      {:ok, _} = ActivityPub.unblock(blocker, ap_blocked, nil, false)
      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
      {:ok, blocker} = CommonsPub.ActivityPub.Adapter.get_raw_actor_by_ap_id(blocker.ap_id)
      assert {:error, _} = CommonsPub.Blocks.find(blocker, blocked)
    end

    test "likes" do
      actor = fake_user!()
      commented_actor = fake_user!()
      thread = fake_thread!(actor, commented_actor)
      comment = fake_comment!(actor, thread)
      {:ok, activity} = CommonsPub.ActivityPub.Publisher.publish("create", comment)
      like_actor = actor()
      {:ok, _, _} = ActivityPub.like(like_actor, activity.object, nil, false)
      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
      {:ok, like_actor} = CommonsPub.ActivityPub.Adapter.get_actor_by_ap_id(like_actor.ap_id)
      assert {:ok, _} = CommonsPub.Likes.one(creator: like_actor.id, context: comment.id)
    end

    test "flags" do
      actor = fake_user!()
      commented_actor = fake_user!()
      thread = fake_thread!(actor, commented_actor)
      comment = fake_comment!(actor, thread)
      {:ok, activity} = CommonsPub.ActivityPub.Publisher.publish("create", comment)
      flag_actor = actor()
      {:ok, account} = ActivityPub.Actor.get_by_local_id(actor.id)

      ActivityPub.flag(%{
        actor: flag_actor,
        context: ActivityPub.Utils.generate_context_id(),
        statuses: [activity.object],
        account: account,
        local: false,
        content: "blocked AND reported!!!!"
      })

      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
      {:ok, flag_actor} = Adapter.get_actor_by_ap_id(flag_actor.ap_id)
      assert {:ok, flag} = CommonsPub.Flags.one(creator: flag_actor.id, context: comment.id)
    end

    test "flags with multiple comments" do
      actor = fake_user!()
      commented_actor = fake_user!()
      thread = fake_thread!(actor, commented_actor)
      comment_1 = fake_comment!(actor, thread)
      {:ok, activity_1} = CommonsPub.ActivityPub.Publisher.publish("create", comment_1)
      comment_2 = fake_comment!(actor, thread)
      {:ok, activity_2} = CommonsPub.ActivityPub.Publisher.publish("create", comment_2)

      flag_actor = actor()
      {:ok, account} = ActivityPub.Actor.get_by_local_id(actor.id)

      ActivityPub.flag(%{
        actor: flag_actor,
        context: ActivityPub.Utils.generate_context_id(),
        statuses: [activity_1.object, activity_2.object],
        account: account,
        local: false,
        content: "blocked AND reported!!!!"
      })

      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
      {:ok, flag_actor} = Adapter.get_actor_by_ap_id(flag_actor.ap_id)
      assert {:ok, flag} = CommonsPub.Flags.one(creator: flag_actor.id, context: comment_1.id)
      assert {:ok, flag} = CommonsPub.Flags.one(creator: flag_actor.id, context: comment_2.id)
    end

    test "flag with only actor" do
      actor = fake_user!()
      flag_actor = actor()
      {:ok, account} = ActivityPub.Actor.get_by_local_id(actor.id)

      ActivityPub.flag(%{
        actor: flag_actor,
        context: ActivityPub.Utils.generate_context_id(),
        statuses: [],
        account: account,
        local: false,
        content: "blocked AND reported!!!!"
      })

      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
      {:ok, flag_actor} = Adapter.get_actor_by_ap_id(flag_actor.ap_id)
      assert {:ok, flag} = CommonsPub.Flags.one(creator: flag_actor.id, context: actor.id)
    end

    test "user deletes" do
      actor = actor()
      ActivityPub.delete(actor, false)
      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
      # IO.inspect(actor: actor)
      # IO.inspect(deleted: Adapter.get_actor_by_ap_id(Map.get(actor, :ap_id)))
      assert {:error, "not found"} =  Adapter.get_actor_by_ap_id(actor.ap_id)
    end

    test "community deletes" do
      actor = community()
      ActivityPub.delete(actor, false)
      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
      assert {:error, "not found"} = Adapter.get_actor_by_ap_id(actor.ap_id)
    end

    test "collection deletes" do
      actor = collection()
      ActivityPub.delete(actor, false)
      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
      assert {:error, "not found"} = Adapter.get_actor_by_ap_id(actor.ap_id)
    end

    test "comment deletes" do
      actor = fake_user!()
      commented_actor = fake_user!()
      thread = fake_thread!(actor, commented_actor, %{is_local: false})
      comment = fake_comment!(actor, thread, %{is_local: false})
      {:ok, activity} = CommonsPub.ActivityPub.Publisher.publish("create", comment)
      object = ActivityPub.Object.get_by_ap_id(activity.data["object"])
      ActivityPub.delete(object, false)
      %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
      assert {:error, _} = CommonsPub.Threads.Comments.one(deleted: false, id: comment.id)
    end

    test "resource deletes" do
      actor = fake_user!()
      community = fake_community!(actor)
      collection = fake_collection!(actor, community)
      resource = fake_resource!(actor, collection)
      {:ok, activity} = CommonsPub.ActivityPub.Publisher.publish("create", resource)
      object = ActivityPub.Object.get_by_ap_id(activity.data["object"])
      ActivityPub.delete(object, false)
      %{success: 1, failure: 0} = Oban.drain_queue(queue: :ap_incoming)
      assert {:error, _} = CommonsPub.Resources.one(deleted: false, id: resource.id)
    end

    test "user updates" do
      user = actor()
      update_data = Map.put(user.data, "name", "kawen")

      data = %{
        "type" => "Update",
        "object" => update_data,
        "actor" => user.ap_id
      }

      ActivityPubWeb.Transmogrifier.handle_incoming(data)
      Oban.drain_queue(queue: :ap_incoming)
      {:ok, user} = Adapter.get_raw_actor_by_ap_id(user.ap_id)
      assert user.name == "kawen"
    end

    test "comm updates" do
      comm = community()
      update_data = Map.put(comm.data, "name", "kawen") |> Map.put("type", "Group")

      data = %{
        "type" => "Update",
        "object" => update_data,
        "actor" => comm.ap_id
      }

      ActivityPubWeb.Transmogrifier.handle_incoming(data)
      Oban.drain_queue(queue: :ap_incoming)
      {:ok, comm} = Adapter.get_raw_actor_by_ap_id(comm.ap_id)
      assert comm.name == "kawen"
    end

    test "coll updates" do
      coll = collection()
      update_data = Map.put(coll.data, "name", "kawen") |> Map.put("type", "Group")

      data = %{
        "type" => "Update",
        "object" => update_data,
        "actor" => coll.ap_id
      }

      ActivityPubWeb.Transmogrifier.handle_incoming(data)
      Oban.drain_queue(queue: :ap_incoming)
      {:ok, coll} = Adapter.get_raw_actor_by_ap_id(coll.ap_id)
      assert coll.name == "kawen"
    end
  end
end

defmodule CommonsPub.ActivityPub.AdapterIntegrationTest do
  use CommonsPub.Web.ConnCase
  import ActivityPub.Factory
  import CommonsPub.Test.Faking
  import Tesla.Mock
  alias CommonsPub.ActivityPub.Adapter

  setup do
    mock(fn
      %{method: :post} -> %Tesla.Env{status: 200}
    end)

    :ok
  end

  describe "adapter integration" do
    test "serve AP actor" do
      user = fake_user!()

      conn =
        build_conn()
        |> get("/pub/actors/#{user.character.preferred_username}")
        |> response(200)
        |> Jason.decode!

        assert conn["preferredUsername"] == user.character.preferred_username
        assert conn["name"] == user.name
        assert conn["summary"] == user.summary
    end

    test "get external followers" do
      actor_1 = actor()
      actor_2 = actor()
      user = fake_user!()
      {:ok, ap_user} = Adapter.get_actor_by_id(user.id)

      ActivityPub.follow(actor_1, ap_user, nil, false)
      ActivityPub.follow(actor_2, ap_user, nil, false)
      Oban.drain_queue(queue: :ap_incoming)
      {:ok, followers} = ActivityPub.Actor.get_external_followers(ap_user)
      assert length(followers) == 2
    end

    test "publish to followers" do
      community = fake_user!() |> fake_community!()
      actor_1 = actor()
      actor_2 = actor()
      {:ok, ap_community} = ActivityPub.Actor.get_by_local_id(community.id)

      ActivityPub.follow(actor_1, ap_community, nil, false)
      ActivityPub.follow(actor_2, ap_community, nil, false)
      Oban.drain_queue(queue: :ap_incoming)

      activity =
        insert(:note_activity, %{
          actor: ap_community,
          data_attrs: %{"cc" => [ap_community.data["followers"]]}
        })

      assert :ok == ActivityPubWeb.Publisher.publish(ap_community, activity)
      assert %{failure: 0, success: 2} = Oban.drain_queue(queue: :federator_outgoing)
    end
  end
end
