defmodule MoodleNetWeb.MemberLive.MemberFollowingLive do
  use MoodleNetWeb, :live_component

  # import MoodleNetWeb.Helpers.Common
  alias MoodleNetWeb.Helpers.{Profiles}

  alias MoodleNetWeb.Component.UserPreviewLive

  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> fetch(assigns)
    }
  end

  defp fetch(socket, assigns) do
    # IO.inspect(assigns.user)
    {:ok, follows} =
      MoodleNetWeb.GraphQL.UsersResolver.user_follows_edge(
        %{id: assigns.user.id},
        %{limit: 10},
        %{context: %{current_user: assigns.current_user}}
      )

    followings =
      Enum.map(
        follows.edges,
        &Profiles.fetch_users_from_context(&1)
      )

    # IO.inspect(users, label: "USER COMMUNITY")
    # following_users = Enum.map(users.edges, &Profiles.prepare(&1, %{icon: true, actor: true}))
    # IO.inspect(following_users, label: "USER COMMUNITY")

    assign(socket,
      users: followings,
      has_next_page: follows.page_info.has_next_page,
      after: follows.page_info.end_cursor,
      before: follows.page_info.start_cursor
    )
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, socket |> assign(page: assigns.page + 1) |> fetch(assigns)}
  end

  def render(assigns) do
    ~L"""
      <div id="member-users">
        <div
        phx-update="append"
        data-page="<%= @page %>"
        class="selected__area">
          <%= for user <- @users do %>
          <div class="preview__wrapper">
            <%= live_component(
                  @socket,
                  UserPreviewLive,
                  id: "user-#{user.id}",
                  user: user
                )
              %>
            </div>
          <% end %>
        </div>
        <%= if @has_next_page do %>
        <div class="pagination">
          <button
            class="button--outline"
            phx-click="load-more"
            phx-target="<%= @pagination_target %>">
            load more
          </button>
        </div>
        <% end %>
      </div>
    """
  end
end