defmodule CommonsPub.Workers.APReceiverWorker do
  use ActivityPub.Workers.WorkerHelper, queue: "ap_incoming"

  @impl Oban.Worker
  def perform(%{args: %{"op" => "handle_activity", "activity_id" => activity_id}}) do
    activity = ActivityPub.Object.get_by_id(activity_id)
    CommonsPub.ActivityPub.Adapter.perform(:handle_activity, activity)
  end
end
