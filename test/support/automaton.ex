# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Web.Test.Automaton do
  @moduledoc "Pagination testing"

  import CommonsPub.Utils.Trendy

  import ExUnit.Assertions
  import Zest

  import Bonfire.GraphQL.Test.GraphQLAssertions
  import CommonsPub.Web.Test.ConnHelpers

  def root_page_test(
        %{
          query: query,
          connection: conn,
          return_key: key,
          default_limit: default_limit,
          total_count: total,
          data: data,
          assert_fn: assert_fn,
          cursor_fn: cursor_fn,
          limit: limit,
          after: aft,
          before: _bef
        } = opts
      ) do
    vars = Map.get(opts, :vars, %{})
    assert is_map(vars)

    page1 =
      scope page: 1, limit: :default do
        page = query_page(query, conn, key, vars, default_limit, total, false, true, cursor_fn)
        each(data, page.edges, assert_fn)
        page
      end

    page_1 =
      scope page: 1, limit: default_limit do
        vars = Map.merge(vars, %{limit => default_limit})
        page = query_page(query, conn, key, vars, default_limit, total, false, true, cursor_fn)
        each(data, page.edges, assert_fn)
        page
      end

    _page2 =
      scope page: 2, limit: default_limit - 1, after: default_limit do
        vars = Map.merge(vars, %{limit => default_limit - 1, aft => page_1.page_info.end_cursor})
        page = query_page(query, conn, key, vars, default_limit - 1, total, true, true, cursor_fn)
        drop_each(data, page.edges, default_limit, assert_fn)
        page
      end

    # page3 = scope [page: 3, limit: default_limit, after: (2*default_limit)-1] do
    #   vars = Map.merge(vars, %{limit => default_limit, aft => page2.page_info.end_cursor})
    #   page = query_page(query, conn, key, vars, default_limit, total, true, false, cursor_fn)
    #   drop_each(data, page.edges, (default_limit*2)-1, assert_fn)
    #   page
    # end

    _page_2 =
      scope page: 2, limit: :default, after: default_limit do
        vars = Map.merge(vars, %{aft => page1.page_info.end_cursor})
        page = query_page(query, conn, key, vars, default_limit, total, true, true, cursor_fn)
        drop_each(data, page.edges, default_limit, assert_fn)
        page
      end

    # _page_3 = scope [page: 3, limit: :default, after: 2 * default_limit] do
    #   vars = Map.merge(vars, %{aft => page_2.page_info.end_cursor})
    #   page = query_page(query, conn, key, vars, 7, total, true, false, cursor_fn)
    #   drop_each(data, page.edges, 2 * default_limit, assert_fn)
    #   page
    # end
  end

  def child_page_test(
        %{
          query: query,
          connection: conn,
          parent_key: parent_key,
          child_key: child_key,
          default_limit: default_limit,
          total_count: total,
          parent_data: parent_data,
          child_data: child_data,
          assert_parent: assert_parent,
          assert_child: assert_child,
          cursor_fn: cursor_fn,
          after: aft,
          before: _bef,
          limit: limit
        } = opts
      ) do
    vars = Map.get(opts, :vars, %{})
    count_key = Map.get(opts, :count_key)
    assert is_map(vars)

    page1 =
      scope page: 1, limit: :default do
        parent = assert_parent.(parent_data, grumble_post_key(query, conn, parent_key, vars))
        page = assert_page(parent[child_key], default_limit, total, false, true, cursor_fn)
        if not is_nil(count_key), do: assert(parent[count_key] == total)
        each(child_data, page.edges, assert_child)
        page
      end

    page_1 =
      scope page: 1, limit: default_limit do
        vars = Map.put(vars, limit, default_limit)
        parent = assert_parent.(parent_data, grumble_post_key(query, conn, parent_key, vars))
        page = assert_page(parent[child_key], default_limit, total, false, true, cursor_fn)
        if not is_nil(count_key), do: assert(parent[count_key] == total)
        each(child_data, page.edges, assert_child)
        page
      end

    _page2 =
      scope page: 2, limit: default_limit - 1, after: default_limit do
        vars = Map.merge(vars, %{limit => default_limit - 1, aft => page_1.page_info.end_cursor})
        parent = assert_parent.(parent_data, grumble_post_key(query, conn, parent_key, vars))
        # TODO s/nil/true/
        page = assert_page(parent[child_key], default_limit - 1, total, true, true, cursor_fn)
        if not is_nil(count_key), do: assert(parent[count_key] == total)
        drop_each(child_data, page.edges, default_limit, assert_child)
        page
      end

    # _page3 = scope [page: 3, limit: default_limit, after: (default_limit * 2) - 1] do
    #   vars = Map.merge(vars, %{limit => 10, aft => page2.page_info.end_cursor})
    #   parent = assert_parent.(parent_data, grumble_post_key(query, conn, parent_key, vars))
    #   page = assert_page(parent[child_key], 8, total, true, false, cursor_fn)
    #   if not is_nil(count_key), do: assert(parent[count_key] == total)
    #   drop_each(child_data, page.edges, 19, assert_child)
    #   page
    # end

    _page_2 =
      scope page: 2, limit: :default, after: default_limit do
        vars = Map.merge(vars, %{aft => page1.page_info.end_cursor})
        parent = assert_parent.(parent_data, grumble_post_key(query, conn, parent_key, vars))
        page = assert_page(parent[child_key], default_limit, total, true, true, cursor_fn)
        if not is_nil(count_key), do: assert(parent[count_key] == total)
        drop_each(child_data, page.edges, default_limit, assert_child)
        page
      end

    # _page_3 = scope [page: 3, limit: :default, after: 2 * default_limit] do
    #   vars = Map.merge(vars, %{aft => page_2.page_info.end_cursor})
    #   parent = assert_parent.(parent_data, grumble_post_key(query, conn, parent_key, vars))
    #   page = assert_page(parent[child_key], default_limit, total, true, true, cursor_fn)
    #   if not is_nil(count_key), do: assert(parent[count_key] == total)
    #   drop_each(child_data, page.edges, 2* default_limit, assert_child)
    #   page
    # end
  end

  defp query_page(query, conn, key, vars, count, total, prev, next, cursor_fn) do
    grumble_post_key(query, conn, key, vars)
    |> assert_page(count, total, prev, next, cursor_fn)
  end

  # defp query_child_page(query, conn, vars, parent_key, child_key, parent_assert, parent_data, child_assert) do
  #   parent = parent_assert(grumble_post_key(query, conn, parent_key, vars)

  # end
end
