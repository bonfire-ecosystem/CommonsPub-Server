# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Web.GraphQL.AccessSchema do
  use Absinthe.Schema.Notation
  alias CommonsPub.Web.GraphQL.AccessResolver
  alias Bonfire.GraphQL.CommonResolver

  object :access_queries do
    field :register_email_accesses, non_null(:register_email_accesses_page) do
      arg(:limit, :integer)
      arg(:before, list_of(non_null(:cursor)))
      arg(:after, list_of(non_null(:cursor)))
      resolve(&AccessResolver.register_email_accesses/2)
    end

    field :register_email_domain_accesses, non_null(:register_email_domain_accesses_page) do
      arg(:limit, :integer)
      arg(:before, list_of(non_null(:cursor)))
      arg(:after, list_of(non_null(:cursor)))
      resolve(&AccessResolver.register_email_domain_accesses/2)
    end
  end

  object :access_mutations do
    field :create_register_email_access, non_null(:register_email_access) do
      arg(:email, non_null(:string))
      resolve(&AccessResolver.create_register_email_access/2)
    end

    field :create_register_email_domain_access, non_null(:register_email_domain_access) do
      arg(:domain, non_null(:string))
      resolve(&AccessResolver.create_register_email_domain_access/2)
    end

    field :delete_register_email_access, :register_email_access do
      arg(:id, non_null(:string))
      resolve(&AccessResolver.delete_register_email_access/2)
    end

    field :delete_register_email_domain_access, :register_email_domain_access do
      arg(:id, non_null(:string))
      resolve(&AccessResolver.delete_register_email_domain_access/2)
    end
  end

  object :register_email_access do
    field(:id, non_null(:string))
    field(:email, non_null(:string))

    field :created_at, non_null(:string) do
      resolve(&CommonResolver.created_at_edge/3)
    end

    field(:updated_at, non_null(:string))
  end

  object :register_email_domain_access do
    field(:id, non_null(:string))
    field(:domain, non_null(:string))

    field :created_at, non_null(:string) do
      resolve(&CommonResolver.created_at_edge/3)
    end

    field(:updated_at, non_null(:string))
  end

  object :register_email_accesses_page do
    field(:page_info, non_null(:page_info))
    field(:edges, non_null(list_of(non_null(:register_email_access))))
    field(:total_count, non_null(:integer))
  end

  object :register_email_domain_accesses_page do
    field(:page_info, non_null(:page_info))
    field(:edges, non_null(list_of(non_null(:register_email_domain_access))))
    field(:total_count, non_null(:integer))
  end
end
