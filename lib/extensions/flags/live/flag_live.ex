defmodule CommonsPub.Web.Component.FlagLive do
  use CommonsPub.Web, :live_component



  def handle_event("flag", %{"message" => message} = _args, socket) do
    {:ok, flag} =
      CommonsPub.Web.GraphQL.FlagsResolver.create_flag(
        %{
          context_id: e(socket.assigns.object, :id, nil),
          message: message
        },
        %{
          context: %{current_user: socket.assigns.current_user}
        }
      )

    IO.inspect(flag, label: "FLAG")

    # IO.inspect(f)
    # TODO: error handling

    {
      :noreply,
      socket
      |> put_flash(:info, "Flagged!")
      # |> assign(community: socket.assigns.comment |> Map.merge(%{is_liked: true}))
      #  |> push_patch(to: "/&" <> socket.assigns.community.username)
    }
  end
end
