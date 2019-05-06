defmodule ActivityPub.Entity do
  require ActivityPub.Guards, as: APG

  alias ActivityPub.{Metadata}

  # FIXME Inject here the builder with a list of aspects (and a list of types)?

  def aspects(entity = %{__ap__: meta}) when APG.is_entity(entity),
    do: Metadata.aspects(meta)

  def fields_for(entity, aspect) when APG.has_aspect(entity, aspect) do
    Map.take(entity, aspect.__aspect__(:fields))
  end

  def fields_for(_, _), do: %{}

  def fields(entity) when APG.is_entity(entity) do
    entity
    |> aspects()
    |> Enum.flat_map(&fields_for(entity, &1))
  end

  def assocs_for(entity, aspect) when APG.has_aspect(entity, aspect),
    do: Map.take(entity, aspect.__aspect__(:associations))

  def assocs_for(_, _), do: %{}

  def assocs(e) when APG.is_entity(e) do
    e
    |> aspects()
    |> Enum.reduce(%{}, fn aspect, acc ->
      Map.take(e, aspect.__aspect__(:associations))
      |> Map.merge(acc)
    end)
  end

  def extension_fields(entity) when APG.is_entity(entity) do
    Enum.reduce(entity, %{}, fn
      {key, _}, acc when is_atom(key) -> acc
      {key, value}, acc when is_binary(key) -> Map.put(acc, key, value)
    end)
  end

  def local?(%{__ap__: ap} = e) when APG.is_entity(e), do: Metadata.local?(ap)

  def status(%{__ap__: %{status: status}} = e) when APG.is_entity(e), do: status

  def local_id(%{__ap__: meta} = e) when APG.is_entity(e), do: Metadata.local_id(meta)

  def persistence(%{__ap__: %{persistence: persistence}} = e) when APG.is_entity(e), do: persistence
end