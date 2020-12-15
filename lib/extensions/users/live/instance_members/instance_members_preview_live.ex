defmodule CommonsPub.Web.InstanceLive.InstanceMembersPreviewLive do
  use CommonsPub.Web, :live_component

  alias CommonsPub.Profiles.Web.ProfilesHelper


  # alias CommonsPub.Web.Component.{
  #   UserPreviewLive
  # }

  alias CommonsPub.Web.GraphQL.{
    UsersResolver
  }

  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> fetch(assigns)
    }
  end

  def fetch(socket, assigns) do
    {:ok, users} =
      UsersResolver.users(%{after: assigns.after, limit: 10}, %{
        context: %{current_user: assigns.current_user}
      })

    members = Enum.map(users.edges, &ProfilesHelper.prepare(&1, %{icon: true, character: true}))

    assign(socket,
      members: members,
      has_next_page: users.page_info.has_next_page,
      after: users.page_info.end_cursor,
      before: users.page_info.start_cursor
    )
  end

  def handle_event("load-more", _, socket),
    do: CommonsPub.Utils.Web.CommonHelper.paginate_next(&fetch/2, socket)
end
