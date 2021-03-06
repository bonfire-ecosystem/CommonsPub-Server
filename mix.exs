# SPDX-License-Identifier: AGPL-3.0-only
# Code.eval_file("mess.exs")

defmodule CommonsPub.Mixfile do
  use Mix.Project

  @library_dev_mode true

  # General configuration of the project
  def project do
    [
      app: :commons_pub,
      version: "0.11.1-dev",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers() ++ [:protocol_ex],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases(),
      name: "CommonsPub",
      homepage_url: "http://CommonsPub.org/",
      source_url: "https://gitlab.com/CommonsPub/Server",
      docs: [
        # The first page to display from the docs
        main: "readme",
        # git branch to link in docs:
        source_ref: "flavour/commonspub",
        logo: "assets/static/images/logo_commonspub.png",
        # extra pages to include
        extras: [
          "README.md",
          "docs/HACKING.md",
          "docs/DEPLOY.md",
          "docs/ARCHITECTURE.md",
          "docs/DEPENDENCIES.md",
          "docs/GRAPHQL.md",
          "docs/MRF.md"
        ],
        output: "docs/exdoc"
      ],
      # can add test dirs to include, eg: "forks/activitypub/test" (if so, the corresponding support dir should also be added to elixirc_paths below)
      test_paths: existing_paths(["test", "forks/activitypub/test"]),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  #
  defp elixirc_paths(:test),
    do: existing_paths(["lib", "test/support", "forks/activitypub/test/support"])

  defp elixirc_paths(:dev), do: ["lib"]
  defp elixirc_paths(_), do: ["lib"]

  @bonfire_deps [
    "pointers",
    "bonfire_common",
    "bonfire_data_access_control",
    "bonfire_data_identity",
    "bonfire_data_social",
    "bonfire_data_activity_pub",
    # "bonfire_me",
    "bonfire_geolocate",
    "bonfire_quantify",
    "bonfire_valueflows",
  ] |> Enum.join(" ")

  # Specifies mix commands
  defp aliases do
    [
      "ecto.rebuild": ["ecto.reset", "ecto.seeds"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.seeds": ["run priv/repo/seeds.exs"],
      "sentry.recompile": ["deps.compile sentry --force", "compile"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      "bonfire.deps.update": ["deps.update #{@bonfire_deps}"],
      "bonfire.deps.clean": ["deps.clean #{@bonfire_deps} --build"],
      "bonfire.deps": ["bonfire.deps.update", "bonfire.deps.clean"],
      updates: ["deps.get", "bonfire.deps.clean", "ecto.migrate"]
    ]
  end

  def deps_list do
    # Mess.deps
    [
      # modularisation for Bonfire
      {:bonfire_geolocate,
       git: "https://github.com/bonfire-ecosystem/bonfire_geolocate",
       branch: "main",
       path: "forks/bonfire_geolocate"},
      {:bonfire_quantify,
       git: "https://github.com/bonfire-ecosystem/bonfire_quantify",
       branch: "main",
       path: "forks/bonfire_quantify"},
      {:bonfire_common,
       override: true,
       git: "https://github.com/bonfire-ecosystem/bonfire_common",
       branch: "main",
       path: "forks/bonfire_common"},
      {:bonfire_api_graphql,
       git: "https://github.com/bonfire-ecosystem/bonfire_api_graphql",
       branch: "main",
       path: "forks/bonfire_api_graphql"},
      {:bonfire_valueflows,
       git: "https://github.com/bonfire-ecosystem/bonfire_valueflows",
       branch: "main",
       path: "forks/bonfire_valueflows"},
      {:bonfire_search,
       git: "https://github.com/bonfire-ecosystem/bonfire_search",
       branch: "main",
       path: "forks/bonfire_search"},
      {:bonfire_tag,
       git: "https://github.com/bonfire-ecosystem/bonfire_tag",
       branch: "main",
       path: "forks/bonfire_tag"},
      {:bonfire_classify,
       git: "https://github.com/bonfire-ecosystem/bonfire_classify",
       branch: "main",
       path: "forks/bonfire_classify"},
      {:bonfire_taxonomy_seeder,
       git: "https://github.com/bonfire-ecosystem/bonfire_taxonomy_seeder",
       branch: "main",
       path: "forks/bonfire_taxonomy_seeder"},
      # graphql
      {
        :absinthe,
        "~> 1.5.3"
        # git: "https://github.com/absinthe-graphql/absinthe", override: true,
      },
      {:absinthe_plug, "~> 1.5"},
      {:absinthe_error_payload, "~> 1.0"},
      # activitypub
      {
        :activity_pub,
        # , path: "forks/activitypub"
        git: "https://gitlab.com/CommonsPub/activitypub", branch: "tbd",
        override: true
      },
      {:nodeinfo, git: "https://github.com/voxpub/nodeinfo", branch: "main"},
      # webserver
      {:cowboy, "~> 2.6"},
      {:plug_cowboy, "~> 2.2"},
      {:cowlib, "~> 2.9"},
      {:plug, "~> 1.10"},
      # security (CORS)
      {:cors_plug, "~> 2.0"},
      # phoenix
      {:phoenix, "~> 1.5"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_integration, "~> 0.8"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_live_view, "~> 0.14"},
      {:floki, "~> 0.27", override: true},
      # File storage
      {:belt, git: "https://github.com/commonspub/belt"},
      # File format parsing
      {:twinkle_star, git: "https://github.com/commonspub/twinkle_star"},
      {:tree_magic, git: "https://github.com/commonspub/tree_magic.ex"},
      # database
      # {:ecto, "~> 3.3.4", override: true},
      # {:ecto_sql, "~> 3.3.4", override: true},
      {:ecto, "~> 3.4", override: true},
      {:ecto_sql, "~> 3.4", override: true},
      {:postgrex, "~> 0.15"},
      # crypto
      {:castore, "~> 0.1"},
      # Username reservation
      {:cloak_ecto, "~> 1.0"},
      # Password hashing
      {:argon2_elixir, "~> 2.3"},
      # Outbound HTTP
      {:hackney, "~> 1.16"},
      {:tesla, "~> 1.3"},
      ## Email
      # sending
      {:bamboo, "~> 1.5"},
      # generic smtp backend
      {:bamboo_smtp, "~> 3.0"},
      # checking validity
      {:email_checker, "~> 0.1"},
      # Monitoring
      # stats
      {:telemetry, "~> 0.4.0"},
      {:phoenix_live_dashboard, "~> 0.2.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      # production only
      # {:sentry, "~> 7.1", runtime: sentry?()},
      # Misc
      {:protocol_ex, "~> 0.4.3"},
      # json
      {:jason, "~> 1.2"},
      # localisation
      {:gettext, "~> 0.18"},
      # camel/snake/kebabification
      {:recase, "~> 0.5"},
      # webpage info extraction
      {:furlex, git: "https://gitlab.com/CommonsPub/furlex"},
      # html parser
      # {:fast_html, "~> 1.0"},
      {:html5ever, "~> 0.8"},
      # job queue
      {:oban, "~> 2.0"},
      # timedate headers
      {:timex, "~> 3.5"},
      # caching
      {:cachex, "~> 3.2"},
      # CommonsPub:
      # process HTML content
      {:html_sanitize_ex, "~> 1.4"},
      {
        :linkify,
        git: "https://gitlab.com/CommonsPub/linkify.git", branch: "master"
        # path: "uploads/linkify"
      },
      # geolocation in postgres
      {:geo_postgis, "~> 3.1"},

      # geocoding
      {:geocoder, "~> 1.0"},
      {:earmark, "~> 1.4"},
      {:slugger, "~> 0.3"},
      # {:pointers, "~> 0.2.2"},
      {
        :pointers,
        # "~> 0.4"
        git: "https://github.com/commonspub/pointers.git", branch: "main", override: true
        # path: "forks/pointers"
        # git: "https://github.com/mayel/pointers.git",
      },
      # {:pointers_ulid, path: "uploads/pointers_ulid", override: true},
      # {:dlex, "~> 0.4", override: true},
      # {:castore, "~> 0.1.0", optional: true},
      # {:mint, github: "ericmj/mint", branch: "master"},
      # {:retrieval, "~> 0.9.1"}, # taxonomy trees
      # {:redix, "~> 0.10.5"}, # Redis client
      # {:ex_redi, "~> 0.1.1"}, # RediSearch client
      # {:redisgraph, "~> 0.1.0"}, # RedisGraph client
      # {:assertions, "~> 0.10"}, # for graphql tests
      # dev/test only:
      {:dbg, "~> 1.0", only: [:dev, :test]},
      {:grumble, "~> 0.1.3"},
      # fake app data generation, also used in prototype API endponts
      {:faker, "~> 0.12"},
      # required by CommonsPub.Utils.Simulation
      {:zest, "~> 0.1.1"},
      # fake data generation for AP - still needed here?
      {:ex_machina, "~> 2.3", only: [:dev, :test]},
      # property testing
      {:stream_data, "~> 0.5"},
      # {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false}, # type checking
      # doc gen
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:licensir, "~> 0.6", only: :dev, runtime: false, git: "https://github.com/mayel/licensir"},
      {:docset_api,
       only: :dev,
       runtime: false,
       git: "https://github.com/mayel/hexdocs_docset_api.git",
       path: "/home/Code/DATA_CONFIGS/hexdocs_docset_api/"},
      # test coverage statistics
      {:excoveralls, "~> 0.10", only: :test},
      # module mocking
      {:mock, "~> 0.3.3", only: :test},
      # autorun tests during dev
      {:cortex, "~> 0.1", only: [:dev, :test]},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false}
    ]
  end

  # Configuration for the OTP application.
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {CommonsPub.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :os_mon,
        :hackney,
        :mime,
        :belt,
        :bamboo,
        :bamboo_smtp
      ]
    ]
  end

  defp releases do
    [
      commons_pub: [
        include_executables_for: [:unix]
      ]
    ]
  end

  def deps() do
    configured_deps = Enum.map(deps_list(), &dep_process/1)
    # IO.inspect(configured_deps, limit: :infinity)
  end

  defp dep_process(dep) do
    case dep do
      {lib, [_] = params} ->
        # library without a hex version specified
        dep_prepare(lib, nil, params)

      {lib, [_ | _] = params} ->
        dep_prepare(lib, nil, params)

      {lib, version, [_ | _] = params} ->
        # library with a hex version and other params specified
        dep_prepare(lib, version, params)

      _ ->
        # library with only a hex version specified
        dep
    end
  end

  defp dep_prepare(lib, nil, params) do
    {lib, dep_params(lib, params)}
  end

  defp dep_prepare(lib, version, params) do
    params = dep_params(lib, params)

    if dep_can_devmode(lib, params) do
      {lib, params}
    else
      {lib, version, params}
    end
  end

  defp dep_params(lib, params) do
    # IO.inspect(lib)
    # IO.inspect(params)
    if dep_can_devmode(lib, params) do
      params
      |> Keyword.drop([:git, :github])
      |> Keyword.put_new(:path, dep_devpath(lib, params))
      |> Keyword.put_new(:override, true)
    else
      Keyword.delete(params, :path)
    end
  end

  defp dep_can_devmode(_lib, params) do
    # IO.inspect(Keyword.has_key?(params, :path))
    # IO.inspect(Keyword.get(params, :path))
    # IO.inspect(File.exists?(Keyword.get(params, :path)))

    @library_dev_mode and Keyword.has_key?(params, :path) and
      File.exists?(Keyword.get(params, :path))
  end

  defp dep_devpath(_lib, params) do
    path = Keyword.get(params, :path)
    IO.inspect(using_lib_path: path)
    path
  end

  defp existing_paths(list) do
    Enum.filter(list, &File.exists?(&1))
  end

  defp sentry?(), do: Mix.env() not in [:dev, :test]
end
