# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Web.GraphQL.ActivitiesSchema do
  use Absinthe.Schema.Notation

  alias CommonsPub.Web.GraphQL.{
    ActivitiesResolver,
    UsersResolver
  }

  alias Bonfire.GraphQL.CommonResolver

  # alias CommonsPub.Collections.Collection
  # alias CommonsPub.Flags.Flag
  # alias CommonsPub.Follows.Follow
  # alias CommonsPub.Likes.Like
  # alias CommonsPub.Communities.Community
  # alias CommonsPub.Resources.Resource
  # alias CommonsPub.Threads.Comment
  # alias CommonsPub.Users.User

  object :activities_queries do
    field :activity, :activity do
      arg(:activity_id, non_null(:string))
      resolve(&ActivitiesResolver.activity/2)
    end
  end

  @desc "An event that appears in a feed"
  object :activity do
    @desc "An instance-local UUID identifying the activity"
    field(:id, non_null(:string))
    @desc "A url for the like, may be to a remote instance"
    field(:canonical_url, :string)

    @desc "The verb describing the activity"
    field(:verb, non_null(:activity_verb))

    @desc "Whether the activity is local to the instance"
    field(:is_local, non_null(:boolean))

    @desc "Whether the activity is public"
    field :is_public, non_null(:boolean) do
      resolve(&CommonResolver.is_public_edge/3)
    end

    @desc "When the activity was created"
    field :created_at, non_null(:string) do
      resolve(&CommonResolver.created_at_edge/3)
    end

    @desc "The user who performed the activity"
    field :user, :user do
      resolve(&UsersResolver.creator_edge/3)
    end

    @desc "The object of the user's verbing"
    field :context, :any_context do
      resolve(&ActivitiesResolver.context_edge/3)
    end
  end

  @desc "Something a user does, in past tense"
  enum(:activity_verb, values: ["created", "updated"])

  # union :activity_context do
  #   description("Activity object")
  #   types([:community, :collection, :resource, :comment, :flag, :follow, :like, :user])
  #   resolve_type(fn
  #     %Collection{}, _ -> :collection
  #     %Comment{},    _ -> :comment
  #     %Community{},  _ -> :community
  #     %Resource{},   _ -> :resource
  #     %Flag{},     _   -> :flag
  #     %Follow{},     _ -> :follow
  #     %Like{},       _ -> :like
  #     %User{},       _ -> :user
  #   end)
  # end

  object :activities_page do
    field(:page_info, non_null(:page_info))
    field(:edges, non_null(list_of(non_null(:activity))))
    field(:total_count, non_null(:integer))
  end
end
