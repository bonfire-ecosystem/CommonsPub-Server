# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Web.GraphQL.LikesSchema do
  use Absinthe.Schema.Notation
  # alias CommonsPub.Collections.Collection
  # alias CommonsPub.Communities.Community
  # alias CommonsPub.Resources.Resource
  # alias CommonsPub.Threads.Comment
  # alias CommonsPub.Users.User
  alias CommonsPub.Web.GraphQL.{ LikesResolver, UsersResolver}
  alias Bonfire.GraphQL.CommonResolver

  object :likes_queries do
    @desc "Fetch a like by ID"
    field :like, :like do
      arg(:like_id, non_null(:string))
      resolve(&LikesResolver.like/2)
    end
  end

  object :likes_mutations do
    @desc "Like a comment, collection, or resource returning the like"
    field :create_like, :like do
      arg(:context_id, non_null(:string))
      resolve(&LikesResolver.create_like/2)
    end
  end

  @desc "A record that a user likes a thing"
  object :like do
    @desc "An instance-local UUID identifying the like"
    field(:id, non_null(:string))
    @desc "A url for the like, may be to a remote instance"
    field(:canonical_url, :string)

    @desc "Whether the like is local to the instance"
    field(:is_local, non_null(:boolean))
    @desc "Whether the like is public"
    field :is_public, non_null(:boolean) do
      resolve(&CommonResolver.is_public_edge/3)
    end

    @desc "When the like was created"
    field :created_at, non_null(:string) do
      resolve(&CommonResolver.created_at_edge/3)
    end

    @desc "When the like was last updated"
    field(:updated_at, non_null(:string))

    @desc "The user who liked"
    field :creator, :user do
      resolve(&UsersResolver.creator_edge/3)
    end

    @desc "The thing that is liked"
    field :context, non_null(:any_context) do
      resolve(&CommonResolver.context_edge/3)
    end
  end

  # union :like_context do
  #   description "A thing which can be liked"
  #   types [:collection, :comment, :community, :resource, :user]
  #   resolve_type fn
  #     %Collection{}, _ -> :collection
  #     %Comment{},    _ -> :comment
  #     %Community{},  _ -> :community
  #     %Resource{},   _ -> :resource
  #     %User{},       _ -> :user
  #   end
  # end

  object :likes_page do
    field(:page_info, non_null(:page_info))
    field(:edges, non_null(list_of(non_null(:like))))
    field(:total_count, non_null(:integer))
  end
end
