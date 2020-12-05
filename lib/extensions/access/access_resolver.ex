# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Web.GraphQL.AccessResolver do
  alias CommonsPub.{Access, GraphQL}
  alias Bonfire.GraphQL
  alias Bonfire.GraphQL.{ResolveRootPage, FetchPage}
  alias CommonsPub.Users.User

  def register_email_accesses(page_opts, info) do
    with {:ok, %User{}} <- GraphQL.admin_or_empty_page(info) do
      ResolveRootPage.run(%ResolveRootPage{
        module: __MODULE__,
        fetcher: :fetch_register_email_accesses,
        page_opts: page_opts,
        paging_opts: %{default_limit: 10, max_limit: 50},
        info: info
      })
    end
  end

  def fetch_register_email_accesses(page_opts, _info) do
    FetchPage.run(%FetchPage{
      queries: Access.RegisterEmailAccessesQueries,
      query: Access.RegisterEmailAccess,
      page_opts: page_opts,
      data_filters: [page: [desc: [created: page_opts]]]
    })
  end

  def register_email_domain_accesses(page_opts, info) do
    with {:ok, %User{}} <- GraphQL.admin_or_empty_page(info) do
      ResolveRootPage.run(%ResolveRootPage{
        module: __MODULE__,
        fetcher: :fetch_register_email_domain_accesses,
        page_opts: page_opts,
        paging_opts: %{default_limit: 10, max_limit: 50},
        info: info
      })
    end
  end

  def fetch_register_email_domain_accesses(page_opts, _info) do
    FetchPage.run(%FetchPage{
      queries: Access.RegisterEmailDomainAccessesQueries,
      query: Access.RegisterEmailDomainAccess,
      page_opts: page_opts,
      data_filters: [page: [desc: [created: page_opts]]]
    })
  end

  ### mutations

  def create_register_email_access(%{email: email}, info) do
    with {:ok, _user} <- GraphQL.admin_or_not_permitted(info),
         do: Access.RegisterEmailAccesses.create(email)
  end

  def create_register_email_domain_access(%{domain: domain}, info) do
    with {:ok, _user} <- GraphQL.admin_or_not_permitted(info),
         do: Access.RegisterEmailDomainAccesses.create(domain)
  end

  def delete_register_email_access(%{id: id}, info) do
    with {:ok, _user} <- GraphQL.admin_or_not_permitted(info),
         {:ok, access} <- Access.RegisterEmailAccesses.one(id: id) do
      Access.hard_delete(access)
    end
  end

  def delete_register_email_domain_access(%{id: id}, info) do
    with {:ok, _user} <- GraphQL.admin_or_not_permitted(info),
         {:ok, access} <- Access.RegisterEmailDomainAccesses.one(id: id) do
      Access.hard_delete(access)
    end
  end
end
