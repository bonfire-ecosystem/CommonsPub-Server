# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule MoodleNetWeb.GraphQL.UploadSchema do
  use Absinthe.Schema.Notation
  alias MoodleNetWeb.GraphQL.UploadResolver

  alias MoodleNet.Collections.Collection
  alias MoodleNet.Comments.Comment
  alias MoodleNet.Communities.Community
  alias MoodleNet.Resources.Resource
  alias MoodleNet.Users.User

  import_types Absinthe.Plug.Types

  object :upload_mutations do
    @desc "Upload an avatar (icon in ActivityPub). Returns the full image."
    field :upload_file, type: :file_upload do
      arg(:context_id, non_null(:id))
      arg(:upload, non_null(:upload))
      arg(:field_type, non_null(:field_type))
      resolve(&UploadResolver.upload/2)
    end
  end

  @desc "An uploaded file, may contain metadata."
  object :file_upload do
    field(:id, non_null(:id))
    field(:url, non_null(:string))
    field(:size, non_null(:integer))
    field(:media_type, non_null(:string))
    field(:metadata, :file_metadata)

    field(:is_public, non_null(:boolean)) do
      resolve(&UploadResolver.is_public/3)
    end

    field(:parent, non_null(:upload_parent)) do
      resolve(&UploadResolver.parent/3)
    end

    field(:uploader, non_null(:user)) do
      resolve(&UploaderResolver.uploader/3)
    end
  end

  @desc """
  Metadata associated with a file.

  None of the parameters are required and are filled depending on the
  file type.
  """
  object :file_metadata do
    field(:width_px, :integer)
    field(:height_px, :integer)
    field(:page_count, :integer)
  end

  @desc """
  The type of an upload field.

  For example an icon or image.
  """
  enum :field_type do
    value :icon, description: "A small icon, also known as an avatar"
    value :image, description: "A large image, also known as a header"
  end

  # TODO
  # object :file_intrinsics do
  # end

  @desc "Supported parents of a file upload."
  union :upload_parent do
    description "A parent of an upload"
    types [:collection, :comment, :community, :resource, :user]
    resolve_type fn
      %Collection{}, _ -> :collection
      %Comment{},    _ -> :comment
      %Community{},  _ -> :community
      %Resource{},   _ -> :resource
      %User{},       _ -> :user
    end
  end
end
