defmodule Organisation.Migrations do
  import Ecto.Migration
  import Pointers.Migration

  def up() do
    # a organisation is a group actor that is home to resources
    create_pointable_table(Organisation) do
      add(:character_id, references("character", on_delete: :delete_all))
      # points to the parent Thing of this character
      add(:context_id, weak_pointer(), null: true)
      add(:extra_info, :map)
    end
  end

  def down() do
    drop_pointable_table(Organisation)
  end

  # def down_circle() do
  #   drop_pointable_table("circle", "01EAQ0ENYEFY2DZHATQWZ2AEEQ")
  # end
end