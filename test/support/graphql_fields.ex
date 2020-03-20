# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.Test.GraphQLFields do

  import Gruff

  def page_info_fields do
    ~w(start_cursor end_cursor has_previous_page has_next_page __typename)a
  end
  
  def page_fields(edge_fields) do
    page_info = Gruff.field(:page_info, fields: page_info_fields())
    edges = Gruff.field(:edges, fields: edge_fields)
    [:total_count, page_info, edges]
  end

  def user_fields(extra \\ []) do
    extra ++
      ~w(id canonical_url preferred_username display_username name summary
         location website icon image follower_count liker_count is_local is_public
         is_disabled created_at updated_at __typename)a
  end

  def auth_payload_fields(extra \\ []) do
    [:__typename, :token, me: me_fields(extra)]
  end

  def me_fields(extra \\ []) do
    [user: user_fields(extra)] ++
      ~w(email wants_email_digest wants_notifications is_confirmed
         is_instance_admin __typename)a
  end

  def thread_fields(extra \\ []) do
    extra ++
      ~w(id canonical_url follower_count is_local
         is_public is_hidden created_at updated_at __typename)a
  end

  def comment_fields(extra \\ []) do
    extra ++
      ~w(id canonical_url content liker_count is_local
         is_public is_hidden created_at updated_at __typename)a
  end

  def community_fields(extra \\ []) do
    extra ++
      ~w(id canonical_url preferred_username display_username
         name summary icon image collection_count follower_count liker_count is_local
         is_public is_disabled created_at updated_at __typename)a
  end

  def collection_fields(extra \\ []) do
    extra ++
      ~w(id canonical_url preferred_username display_username name summary
         icon resource_count follower_count liker_count is_local
         is_public is_disabled created_at updated_at __typename)a
  end

  def resource_fields(extra \\ []) do
    extra ++
      ~w(id canonical_url name summary icon url license liker_count is_local
         is_public is_disabled created_at updated_at __typename)a
  end

  def feature_fields(extra \\ []) do
    extra ++ ~w(id canonical_url is_local created_at __typename)a
  end

  def flag_fields(extra \\ []) do
    extra ++
      ~w(id canonical_url message is_resolved is_local created_at updated_at __typename)a
  end

  def like_fields(extra \\ []) do
    extra ++ ~w(id canonical_url is_local is_public created_at updated_at __typename)a
  end

  def follow_fields(extra \\ []) do
    extra ++ ~w(id canonical_url is_local is_public created_at updated_at __typename)a
  end

  def followed_collection_fields(extra \\ []) do
    extra ++ [follow: follow_fields, collection: collection_fields()]
  end

  def followed_community_fields(extra \\ []) do
    extra ++ [follow: follow_fields, community: community_fields()]
  end


  def activity_fields(extra \\ []) do
    extra ++ ~w(is canonical_url verb is_local is_public created_at __typename)a
  end

  # def tag_category_basics() do
  #   """
  #   id canonicalUrl name
  #   isLocal isPublic createdAt __typename
  #   """
  # end

  # def tag_basics() do
  #   """
  #   id canonicalUrl name
  #   isLocal isPublic createdAt __typename
  #   """
  # end

  # def tagging_basics() do
  #   """
  #   id canonicalUrl
  #   isLocal isPublic createdAt __typename
  #   """
  # end

  # def language_fields(extra \\ []) do
  #   """
  #   id isoCode2 isoCode3 englishName localName createdAt updatedAt __typename
  #   """
  # end

  # def country_basics() do
  #   """
  #   id isoCode2 isoCode3 englishName localName createdAt updatedAt __typename
  #   """
  # end
  
  def gen_query(param_name, field_fn, options) do
    params = Keyword.get(options, :params, [])
    name = Keyword.get(options, :name, "test")
    query name: name, params: params,
      param: param(param_name, type!(:string)),
      field: field_fn.(options)
  end

  def gen_query(field_fn, options) do
    params = Keyword.get(options, :params, [])
    name = Keyword.get(options, :name, "test")
    query name: name, params: params, field: field_fn.(options)
  end

  def gen_subquery(arg_name, field_name, fields_fn, options) do
    args = Keyword.get(options, :args, [])
    fields = Keyword.get(options, :fields, [])
    field field_name, args: args,
      arg: arg(arg_name, var(arg_name)),
      fields: fields_fn.(fields)
  end

  def gen_subquery(field_name, fields_fn, options) do
    args = Keyword.get(options, :args, [])
    fields = Keyword.get(options, :fields, [])
    field field_name, args: args,
      fields: fields_fn.(fields)
  end

  def page_subquery(arg_name, field_name, fields_fn, options) do
    args = Keyword.get(options, :args, [])
    fields = Keyword.get(options, :fields, [])
    field field_name, args: args,
      arg: arg(arg_name, var(arg_name)),
      fields: page_fields(fields_fn.(fields))
  end

  def page_subquery(field_name, fields_fn, options) do
    args = Keyword.get(options, :args, [])
    fields = Keyword.get(options, :fields, [])
    field field_name, args: args,
      fields: page_fields(fields_fn.(fields))
  end

  def gen_mutation(params, field_fn, options) do
    params2 = Keyword.get(options, :params, [])
    name = Keyword.get(options, :name, "test")
    mutation name: name, params: params, params: params2, field: field_fn.(options)
  end

  def gen_submutation(args, field_name, field_fn, options) do
    args2 = Keyword.get(options, :args, [])
    fields = Keyword.get(options, :fields, [])
    field field_name, args: args, args: args2, fields: field_fn.(fields)
  end

  ### collections

  def collection_spread(fields \\ []) do
    object_spread(:collection, fields: collection_fields(fields))
  end

  def collection_query(options \\ []) do
    gen_query(:collection_id, &collection_subquery/1, options)
  end

  def collection_subquery(options \\ []) do
    gen_subquery(:collection_id, :collection, &collection_fields/1, options)
  end

  def collections_query(options \\ []) do
    gen_query(
      &collections_subquery/1,
      [{:params, [after: :cursor, before: :cursor, limit: :int]} | options]
    )
  end

  def collections_subquery(options \\ []) do
    page_subquery(
      :collections, &collection_fields/1,
      [{:args, [after: var(:after), before: var(:before), limit: var(:limit)]} | options ]
    )
  end

  def create_collection_mutation(options \\ []) do
    [collection: type!(:collection_input), community_id: type!(:string)]
    |> gen_mutation(&create_collection_submutation/1, options)
  end

  def create_collection_submutation(options \\ []) do
    [collection: var(:collection), community_id: var(:community_id)]
    |> gen_submutation(:create_collection, &collection_fields/1, options)
  end

  def update_collection_mutation(options \\ []) do
    [collection: type!(:collection_update_input), collection_id: type!(:string)]
    |> gen_mutation(&update_collection_submutation/1, options)
  end

  def update_collection_submutation(options \\ []) do
    [collection: var(:collection), collection_id: var(:collection_id)]
    |> gen_submutation(:update_collection, &collection_fields/1, options)
  end


  ### communities


  def community_spread(fields \\ []) do
    object_spread(:community, fields: community_fields(fields))
  end

  def community_query(options \\ []) do
    gen_query(:community_id, &community_subquery/1, options)
  end

  def community_subquery(options \\ []) do
    gen_subquery(:community_id, :community, &community_fields/1, options)
  end

  def communities_query(options \\ []) do
    gen_query(&communities_subquery/1, options)
  end

  def communities_subquery(options \\ []) do
    page_subquery(:communities, &community_fields/1, options)
  end

  def create_community_mutation(options \\ []) do
    [community: type!(:community_input)]
    |> gen_mutation(&create_community_submutation/1, options)
  end

  def create_community_submutation(options \\ []) do
    [community: var(:community)]
    |> gen_submutation(:create_community, &community_fields/1, options)
  end

  def update_community_mutation(options \\ []) do
    [community: type!(:community_update_input), community_id: type!(:string)]
    |> gen_mutation(&update_community_submutation/1, options)
  end

  def update_community_submutation(options \\ []) do
    [community: var(:community), community_id: var(:community_id)]
    |> gen_submutation(:update_community, &community_fields/1, options)
  end


  ### flags


  def flag_query(options \\ []) do
    gen_query(:flag_id, &flag_subquery/1, options)
  end

  def flag_subquery(options \\ []) do
    gen_subquery(:flag_id, :flag, &flag_fields/1, options)
  end

  def flags_query(options \\ []) do
    gen_query(:flags, &flags_subquery/1, options)
  end

  def flags_subquery(options \\ []) do
    page_subquery(:flags, &flag_fields/1, options)
  end

  def create_flag_mutation(options \\ []) do
    [flag: type!(:flag_input)]
    |> gen_mutation(&create_flag_submutation/1, options)
  end

  def create_flag_submutation(options \\ []) do
    [flag: var(:flag)]
    |> gen_submutation(:create_flag, &flag_fields/1, options)
  end

  def update_flag_mutation(options \\ []) do
    [flag: type!(:flag_input), flag_id: type!(:string)]
    |> gen_mutation(&create_flag_submutation/1, options)
  end

  def update_flag_submutation(options \\ []) do
    [flag: var(:flag_input), flag_id: var(:flag_id)]
    |> gen_submutation(:update_flag, &flag_fields/1, options)
  end

  ### features

  def feature_query(options \\ []) do
    gen_query(:feature_id, &feature_subquery/1, options)
  end

  def feature_subquery(options \\ []) do
    gen_subquery(:feature_id, :feature, &feature_fields/1, options)
  end

  def features_query(options \\ []) do
    gen_query(:features, &features_subquery/1, options)
  end

  def features_subquery(options \\ []) do
    page_subquery(:features, &feature_fields/1, options)
  end

  ### follows

  def follow_query(options \\ []) do
    gen_query(:follow_id, &follow_subquery/1, options)
  end

  def follow_subquery(options \\ []) do
    gen_subquery(:follow_id, :follow, &follow_fields/1, options)
  end

  def follows_query(options \\ []) do
    gen_query(:follows, &follows_subquery/1, options)
  end

  def follows_subquery(options \\ []) do
    page_subquery(:follows, &follow_fields/1, options)
  end

  def create_follow_mutation(options \\ []) do
    [context_id: type!(:string)]
    |> gen_mutation(&create_follow_submutation/1, options)
  end

  def create_follow_submutation(options \\ []) do
    [context_id: var(:context_id)]
    |> gen_submutation(:create_follow, &follow_fields/1, options)
  end

  def follow_remote_actor_mutation(options \\ []) do
    [url: type!(:string)]
    |> gen_mutation(&follow_remote_actor_submutation/1, options)
  end

  def follow_remote_actor_submutation(options \\ []) do
    [url: var(:url)]
    |> gen_submutation(:createFollowByURL, &follow_fields/1, options)
  end


  ### likes


  def like_query(options \\ []) do
    gen_query(:like_id, &like_subquery/1, options)
  end

  def like_subquery(options \\ []) do
    gen_subquery(:like_id, :like, &like_fields/1, options)
  end

  def likers_subquery(options \\ []) do
    page_subquery(:likers, &like_fields/1, options)
  end

  def likes_subquery(options \\ []) do
    page_subquery(:likes, &like_fields/1, options)
  end

  def create_like_mutation(options \\ []) do
    [context_id: type!(:string)]
    |> gen_mutation(&create_like_submutation/1, options)
  end

  def create_like_submutation(options \\ []) do
    [context_id: var(:context_id)]
    |> gen_submutation(:create_like, &like_fields/1, options)
  end


  ### resources


  def resource_spread(fields \\ []) do
    object_spread(:resource, fields: resource_fields(fields))
  end

  def resource_query(options \\ []) do
    gen_query(:resource_id, &resource_subquery/1, options)
  end

  def resource_subquery(options \\ []) do
    gen_subquery(:resource_id, :resource, &resource_fields/1, options)
  end

  def resources_query(options \\ []) do
    gen_query(:resources, &resources_subquery/1, options)
  end

  def resources_subquery(options \\ []) do
    page_subquery(:resources, &resource_fields/1, options)
  end

  def create_resource_mutation(options \\ []) do
    [collection_id: type!(:string), resource: type!(:resource_input)]
    |> gen_mutation(&create_resource_submutation/1, options)
  end

  def create_resource_submutation(options \\ []) do
    [collection_id: var(:collection_id), resource: var(:resource)]
    |> gen_submutation(:create_resource, &resource_fields/1, options)
  end

  def update_resource_mutation(options \\ []) do
    [resource_id: type!(:string), resource: type!(:resource_input)]
    |> gen_mutation(&update_resource_submutation/1, options)
  end

  def update_resource_submutation(options \\ []) do
    [resource_id: var(:resource_id), resource: var(:resource)]
    |> gen_submutation(:update_resource, &resource_fields/1, options)
  end

  def copy_resource_mutation(options \\ []) do
    [collection_id: type!(:string), resource_id: type!(:string)]
    |> gen_mutation(&copy_resource_submutation/1, options)
  end

  def copy_resource_submutation(options \\ []) do
    [collection_id: var(:collection_id), resource_id: var(:resource_id)]
    |> gen_submutation(:copy_resource, &resource_fields/1, options)
  end

  ### threads


  def threads_subquery(options \\ []) do
    args = Keyword.get(options, :args, [])
    fields = Keyword.get(options, :fields, [])
    field :threads, args: args,
      fields: page_fields(thread_fields(fields))
  end


  ### comments


  def comments_subquery(options \\ []) do
    args = Keyword.get(options, :args, [])
    fields = Keyword.get(options, :fields, [])
    field :comments, args: args,
      fields: page_fields(comment_fields(fields))
  end

  ### users

  def user_spread(fields \\ []) do
    object_spread(:user, fields: user_fields(fields))
  end

  def me_query(fields \\ []) do
    query name: :test, fields: [me: me_fields(fields)]
  end

  def username_available_query() do
    query name: :test, params: [username: type!(:string)],
      fields: [field(:username_available, args: [username: var(:username)])]
  end

  def user_query(options \\ []) do
    gen_query(:user_id, &user_subquery/1, options)
  end

  def user_subquery(options \\ []) do
    gen_subquery(:user_id, :user, &user_fields/1, options)
  end

  def users_query(options \\ []) do
    gen_query(&users_subquery/1, options)
  end

  def users_subquery(options \\ []) do
    page_subquery(:users, &user_fields/1, options)
  end

  def create_user_mutation(options \\ []) do
    [user: type!(:registration_input)]
    |> gen_mutation(&create_user_submutation/1, options)
  end

  def create_user_submutation(options \\ []) do
    [user: var(:user)]
    |> gen_submutation(:create_user, &me_fields/1, options)
  end

  def confirm_email_mutation(options \\ []) do
    [token: type!(:string)]
    |> gen_mutation(&confirm_email_submutation/1, options)
  end

  def confirm_email_submutation(options \\ []) do
    [token: var(:token)]
    |> gen_submutation(:confirm_email, &auth_payload_fields/1, options)
  end

  def create_session_mutation(options \\ []) do
    [email: type!(:string), password: type!(:string)]
    |> gen_mutation(&create_session_submutation/1, options)
  end

  def create_session_submutation(options \\ []) do
    [email: var(:email), password: var(:password)]
    |> gen_submutation(:create_session, &auth_payload_fields/1, options)
  end

  def reset_password_request_mutation(options \\ []) do
    mutation name: :test,
      params: [email: type!(:string)],
      fields: [field(:reset_password_request, args: [email: var(:email)])]
  end

  def reset_password_mutation(options \\ []) do
    [token: type!(:string), password: type!(:string)]
    |> gen_mutation(&reset_password_submutation/1, options)
  end

  def reset_password_submutation(options \\ []) do
    [token: var(:token), password: var(:password)]
    |> gen_submutation(:reset_password, &auth_payload_fields/1, options)
  end

  def update_profile_mutation(options \\ []) do
    [profile: type!(:update_profile_input)]
    |> gen_mutation(&update_profile_submutation/1, options)
  end

  def update_profile_submutation(options \\ []) do
    [profile: var(:profile)]
    |> gen_submutation(:update_profile, &me_fields/1, options)
  end

  def delete_self_mutation(options \\ []) do
    [i_am_sure: type!(:boolean)]
    |> gen_mutation(&delete_self_submutation/1, options)
  end

  def delete_self_submutation(_options \\ []) do
    field(:delete_self, args: [i_am_sure: var(:i_am_sure)])
  end

  def delete_session_mutation(options \\ []) do
    mutation(name: :test, fields: [:delete_session])
  end

  def feature_basics() do
    """
    id canonicalUrl isLocal createdAt __typename
    """
  end
end