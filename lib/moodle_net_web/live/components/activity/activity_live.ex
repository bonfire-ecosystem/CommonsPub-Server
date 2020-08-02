defmodule MoodleNetWeb.Component.ActivityLive do
  use MoodleNetWeb, :live_component

  import MoodleNetWeb.Helpers.Common

  alias MoodleNetWeb.Component.{PreviewLive, PreviewActionsLive}

  # alias MoodleNetWeb.Component.DiscussionPreviewLive

  alias MoodleNetWeb.Helpers.{Activites}

  def update(assigns, socket) do
    activity_id = e(assigns, :activity, :id, random_string(6))
    preview_id = activity_id <> "-" <> e(assigns, :activity, :context, :id, random_string(6))

    if(Map.has_key?(assigns, :activity)) do
      reply_link =
        "/!" <>
          e(e(assigns.activity, :context, assigns.activity), :thread_id, "new") <>
          "/discuss/" <> e(e(assigns.activity, :context, assigns.activity), :id, "") <> "#reply"

      {:ok,
       assign(socket,
         activity: Activites.prepare(assigns.activity, assigns.current_user),
         current_user: assigns.current_user,
         reply_link: reply_link,
         activity_id: activity_id,
         preview_id: preview_id
       )}
    else
      {:ok,
       assign(socket,
         activity: %{},
         current_user: assigns.current_user,
         reply_link: nil,
         activity_id: activity_id,
         preview_id: preview_id
       )}
    end
  end
end