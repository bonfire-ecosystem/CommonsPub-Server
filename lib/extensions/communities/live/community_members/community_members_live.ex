defmodule MoodleNetWeb.CommunityLive.CommunityMembersLive do
  use MoodleNetWeb, :live_component
  alias MoodleNetWeb.Helpers.{Profiles}

  alias MoodleNetWeb.Component.{
    UserPreviewLive
  }

  def update(assigns, socket) do
    # IO.inspect(assigns, label: "ASSIGNS:")
    {
      :ok,
      socket
      |> assign(assigns)
      |> fetch(assigns)
    }
  end

  defp fetch(socket, assigns) do
    {:ok, follows} =
      MoodleNetWeb.GraphQL.FollowsResolver.followers_edge(
        %{id: assigns.community.id},
        %{limit: 10},
        %{context: %{current_user: assigns.current_user}}
      )

    IO.inspect(follows: follows)

    followings =
      Enum.map(
        follows.edges,
        &Profiles.fetch_users_from_creator(&1)
      )

    # IO.inspect(followings, label: "User COMMUNITY:")

    # followings = Enum.dedup_by(followings, fn %{id: id} -> id end)

    assign(socket,
      members: followings,
      has_next_page: follows.page_info.has_next_page,
      after: follows.page_info.end_cursor,
      before: follows.page_info.start_cursor
    )
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, socket |> assign(page: assigns.page + 1) |> fetch(assigns)}
  end
end