defmodule MoodleNetWeb.SearchLive.ResultsLive do
  use MoodleNetWeb, :live_component
  alias MoodleNetWeb.Component.{ActivityLive, PreviewLive}

  import MoodleNetWeb.Helpers.Common

  def render(assigns) do
    ~L"""
    <div
    id="search_results">
    <div
    phx-update="append"
    data-page="<%= @page %>"
    class="selected__area">
      <%= for hit <- @hits do %>
        <%=
        if Map.has_key?(hit, :creator) do
          activity = hit |> Map.merge(%{context_type: String.downcase(e(hit, :index_type, ""))})

          live_component(
            @socket,
            ActivityLive,
            id: "timeline-activity-#{hit.id}",
            activity: activity,
            current_user: @current_user
          )
        else
          live_component(
            @socket,
            PreviewLive,
            object: hit,
            object_type: String.downcase(e(hit, :index_type, "")),
            current_user: @current_user,
            preview_id: hit.id
          )
        end
        %>
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
