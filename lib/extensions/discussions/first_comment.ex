# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Threads.FirstComment do
  @moduledoc """
  The most recently created comment for a thread
  """
  use MoodleNet.Common.Schema
  alias MoodleNet.Threads.{Comment, Thread}

  view_schema "mn_thread_first_comment" do
    belongs_to(:thread, Thread, primary_key: true)
    belongs_to(:comment, Comment)
  end
end