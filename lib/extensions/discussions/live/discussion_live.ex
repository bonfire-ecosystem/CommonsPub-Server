defmodule CommonsPub.Web.DiscussionLive do
  use CommonsPub.Web, :live_view

  alias CommonsPub.Web.GraphQL.{ThreadsResolver, CommentsResolver}

  alias CommonsPub.Discussions.Web.DiscussionsHelper

  alias CommonsPub.Web.Discussion.DiscussionCommentLive

  def mount(%{"id" => thread_id} = params, session, socket) do
    socket = init_assigns(params, session, socket)

    current_user = socket.assigns.current_user

    {:ok, thread} =
      ThreadsResolver.thread(%{thread_id: thread_id}, %{
        context: %{current_user: current_user}
      })

    thread = DiscussionsHelper.prepare_thread(thread, :with_context)
    IO.inspect(thread, label: "Thread")
    # TODO: tree of replies & pagination
    {:ok, comments} =
      CommentsResolver.comments_edge(thread, %{limit: 15}, %{
        context: %{current_user: current_user}
      })

    # comments_edges = comments.edges
    comments_edges = DiscussionsHelper.prepare_comments(comments.edges, current_user)

    # IO.inspect(comments_edges, label: "COMMENTS")

    tree = DiscussionsHelper.build_comment_tree(comments_edges)

    # IO.inspect(tree: tree)

    {main_comment_id, _} = Enum.fetch!(tree, 0)

    # subscribe to the thread for realtime updates
    CommonsPub.Utils.Web.CommonHelper.pubsub_subscribe(thread_id, socket)

    {:ok,
     assign(socket,
       #  current_user: current_user,
       reply_to: main_comment_id,
       thread: thread,
       #  main_comment: main_comment,
       comments: tree
     )}
  end

  def handle_params(
        %{"id" => _thread_id, "sub_id" => comment_id} = _params,
        _session,
        socket
      ) do
    {_, reply_comment} =
      Enum.find(socket.assigns.comments, fn element ->
        {_id, comment} = element
        comment.id == comment_id
      end)

    {:noreply,
     assign(socket,
       reply_to: comment_id,
       reply: reply_comment
     )}
  end

  def handle_params(%{"id" => _thread_id} = _params, _session, socket) do
    {:noreply,
     assign(socket,
       reply_to: nil,
       reply: nil
     )}
  end

  def handle_event("reply", %{"content" => content} = data, socket) do
    # IO.inspect(data, label: "DATA")

    if(is_nil(content) or is_nil(socket.assigns.current_user)) do
      {:noreply,
       socket
       |> put_flash(:error, "Please write something...")}
    else
      # CommonsPub.Web.Plugs.Auth.login(socket, session.current_user, session.token)

      comment = input_to_atoms(data)

      reply_to_id =
        if !is_nil(socket.assigns.reply_to) do
          socket.assigns.reply_to
          # else
          #   socket.assigns.main_comment.id
        end

      {:ok, _comment} =
        CommonsPub.Web.GraphQL.CommentsResolver.create_reply(
          %{
            thread_id: socket.assigns.thread.id,
            in_reply_to_id: reply_to_id,
            comment: comment
          },
          %{context: %{current_user: socket.assigns.current_user}}
        )

      # TODO: error handling

      {
        :noreply,
        socket
        |> put_flash(:info, "Replied!")
        # redirect in order to reload comments, TODO: just add comment which was returned by resolver?
        #  |> push_redirect(
        #    to: "/!" <> socket.assigns.thread.id <> "/discuss/" <> (reply_to_id || "")
        #  )
      }
    end
  end

  @doc """
  Forward PubSub activities in timeline to our timeline component
  """
  def handle_info({:pub_feed_comment, comment}, socket),
    do: CommonsPub.Discussions.Web.DiscussionsHelper.pubsub_receive(comment, socket)
end
