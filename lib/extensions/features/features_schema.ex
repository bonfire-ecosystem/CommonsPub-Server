# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Web.GraphQL.FeaturesSchema do
  use Absinthe.Schema.Notation
  # alias CommonsPub.Collections.Collection
  # alias CommonsPub.Communities.Community
  alias CommonsPub.Web.GraphQL.{ FeaturesResolver, UsersResolver}
  alias Bonfire.GraphQL.CommonResolver

  object :features_queries do
    field :feature, :feature do
      arg(:feature_id, non_null(:string))
      resolve(&FeaturesResolver.feature/2)
    end

    field :features, :features_page do
      arg(:limit, :integer)
      arg(:before, list_of(:cursor))
      arg(:after, list_of(:cursor))
      resolve(&FeaturesResolver.features/2)
    end
  end

  object :features_mutations do
    @desc "Feature a community, or collection, returning the feature"
    field :create_feature, :feature do
      arg(:context_id, non_null(:string))
      resolve(&FeaturesResolver.create_feature/2)
    end
  end

  @desc "A featured piece of content"
  object :feature do
    @desc "An instance-local UUID identifying the feature"
    field(:id, non_null(:string))
    @desc "A url for the feature, may be to a remote instance"
    field(:canonical_url, :string)

    @desc "Whether the feature is local to the instance"
    field(:is_local, non_null(:boolean))

    @desc "When the feature was created"
    field :created_at, non_null(:string) do
      resolve(&CommonResolver.created_at_edge/3)
    end

    @desc "The user who featured"
    field :creator, :user do
      resolve(&UsersResolver.creator_edge/3)
    end

    @desc "The thing that is being featured"
    field :context, :any_context do
      resolve(&CommonResolver.context_edge/3)
    end
  end

  # union :feature_context do
  #   description "A thing that can be featured"
  #   types [:collection, :community]
  #   resolve_type fn
  #     %Collection{}, _ -> :collection
  #     %Community{},  _ -> :community
  #   end
  # end

  object :features_page do
    field(:page_info, non_null(:page_info))
    field(:edges, non_null(list_of(non_null(:feature))))
    field(:total_count, non_null(:integer))
  end
end
