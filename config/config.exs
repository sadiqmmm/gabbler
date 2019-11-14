# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :gabbler, GabblerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "TvQAT9ayKUye68lEOQ5+0ioQy5GBMgEd0Wqv4wI+0FJfOV3qolE+cnc/texT42Lg",
  render_errors: [view: GabblerWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Gabbler.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :gabbler, GabblerWeb.Endpoint,
  live_view: [
    signing_salt: "generatepropersaltforproduction"
  ]

# GABBLER SETTINGS
config :gabbler,
  # Logo name to use from from images/logo/*
  logo: "smileys",
  # Hooks for Captcha exist but not working with liveview yet
  captcha: :off,
  # Gabbler.Post.Upload - keeping as :off until LiveView implements uploads
  uploads: :off,
  
  page_title: "Smiley's Pub",
  page_desc: "Build Your Community",
  sub_nav: ["/h/all", "/h/tag_tracker", "/r/gabbler_testing", "/r/gabbler_feedback"],
  
  # Max tags to put in a post
  post_max_tags: 3,
  # Max unique tags to track the scores of
  tags_max_per_server: 500,
  # Posts to keep in memory per tag
  tags_max_posts_per_topic: 10,
  # Amount of tags to keep in the trending list at maximum
  tags_max_trending: 20,
  # Popular posts from trending tags shown in default trending list
  tags_max_posts_client: 20,
  # Hours
  tags_score_duration: 24,

  logic_meta: Gabbler.Post.Meta,

  query: GabblerData.Query,
  # Coming soon
  image_uploads: :off,
  # Possibly added later
  video_uploads: :off,
  gzip: :off,
  # Multiplier for 5 minute increments. Delay between ability to post for users
  post_delay_mult: 12,
  # Multiplier for private score when user votes. nil for neutral and no reputation actions
  reputation_mult: nil

# GETTEXT (LOCALE/LANGUAGE)
config :gettext,
  default_locale: "en"

# QUANTUM - JOB SCHEDULING
config :gabbler, Gabbler.Scheduler,
  jobs: [
    # Every minute
    {"* * * * *", {Gabbler.TagTracker, :sort, []}}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
