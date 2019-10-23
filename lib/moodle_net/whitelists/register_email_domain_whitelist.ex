# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Whitelists.RegisterEmailDomainWhitelist do
  @moduledoc """
  A simple standalone schema listing domains for which emails at those
  domains are permitted to register a MoodleNet account while public
  signup is disabled.
  """
  use MoodleNet.Common.Schema
  alias Ecto.Changeset
  import MoodleNet.Common.Changeset, only: [validate_email_domain: 2]
  alias MoodleNet.Whitelists.RegisterEmailDomainWhitelist

  standalone_schema "mn_whitelist_register_email_domain" do
    field(:domain, :string)
    timestamps()
  end

  @cast ~w(domain)a
  @required @cast
  
  @doc "A changeset for both creation and update purposes"
  def changeset(entry \\ %RegisterEmailDomainWhitelist{}, fields)
  def changeset(%RegisterEmailDomainWhitelist{}=entry, fields) do
    entry
    |> Changeset.cast(fields, @cast)
    |> Changeset.validate_required(@required)
    |> validate_email_domain(:domain)
    |> Changeset.unique_constraint(:domain)
  end
  
end