defmodule MoodleNet.Activity do
  # This should be ActivityPub.Activity
  # ActivityPub activity schema
  # FIXME
  # * It should not use Repo in this module
  # * I'd move query functions to a new module ActivityPub.ActivityQueries
  # MAYBE
  # normalize the relation with "Actor" and "Object"?
  use Ecto.Schema
  alias MoodleNet.{Repo, Activity, Notification}
  import Ecto.Query

  schema "activities" do
    field(:data, :map)
    field(:local, :boolean, default: true)
    field(:actor, :string)
    field(:recipients, {:array, :string})
    has_many(:notifications, Notification, on_delete: :delete_all)

    timestamps()
  end

  # Has unique index :)
  # This function goes in `ActivityPub`
  @doc """
  Returns the `Activity` by ActivityPub ID, which is a string
  """
  def get_by_ap_id(ap_id) do
    Repo.one(
      from(
        activity in Activity,
        where: fragment("(?)->>'id' = ?", activity.data, ^to_string(ap_id))
      )
    )
  end

  # TODO:
  # Go through these and fix them everywhere.
  # Wrong name, only returns create activities
  def all_by_object_ap_id_q(ap_id) do
    from(
      activity in Activity,
      where:
        fragment(
          "coalesce((?)->'object'->>'id', (?)->>'object') = ?",
          activity.data,
          activity.data,
          ^to_string(ap_id)
        ),
      where: fragment("(?)->>'type' = 'Create'", activity.data)
    )
  end

  # Wrong name, returns all.
  def all_non_create_by_object_ap_id_q(ap_id) do
    from(
      activity in Activity,
      where:
        fragment(
          "coalesce((?)->'object'->>'id', (?)->>'object') = ?",
          activity.data,
          activity.data,
          ^to_string(ap_id)
        )
    )
  end

  # Wrong name plz fix thx
  def all_by_object_ap_id(ap_id) do
    Repo.all(all_by_object_ap_id_q(ap_id))
  end

  # bad: used in mastodon_api/views/status_view...
  def create_activity_by_object_id_query(ap_ids) do
    from(
      activity in Activity,
      where:
        fragment(
          "coalesce((?)->'object'->>'id', (?)->>'object') = ANY(?)",
          activity.data,
          activity.data,
          ^ap_ids
        ),
      where: fragment("(?)->>'type' = 'Create'", activity.data)
    )
  end

  def get_create_activity_by_object_ap_id(ap_id) when is_binary(ap_id) do
    create_activity_by_object_id_query([ap_id])
    |> Repo.one()
  end

  # just matching everything to return nil seems a shortcut
  def get_create_activity_by_object_ap_id(_), do: nil

  # IMPORTANT
  # So normalize it is just find local copy by id, strange
  # I need more info to resolve this
  # This is very used
  def normalize(obj) when is_map(obj), do: Activity.get_by_ap_id(obj["id"])
  def normalize(ap_id) when is_binary(ap_id), do: Activity.get_by_ap_id(ap_id)
  def normalize(_), do: nil
end