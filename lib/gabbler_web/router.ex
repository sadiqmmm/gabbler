defmodule GabblerWeb.Router do
  use GabblerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Gabbler.Auth.Pipeline
  end

  pipeline :auth do
    plug Gabbler.Auth.Pipeline
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GabblerWeb do
    pipe_through [:browser, :auth]

    # GABBLER
    get "/", PageController, :index
    get "/about", PageController, :about
    get "/tos", PageController, :tos

    # ROOM
    get "/h/all", PageController, :index
    get "/h/tag_tracker", PageController, :tag_tracker
    get "/r/:room", RoomController, :room
    get "/r/:room/view/:mode", RoomController, :room
    get "/room/new", RoomController, :new

    # ROOM -> ROOM MANAGEMENT
    #get "/room/:roomname/manage", RoomManageController, :manage
    #get "/room/:roomname/manage/mods", RoomManageController, :manage_mods
    #post "/room/:roomname/new", RoomManageController, :allowuser
    #post "/room/:roomname/manage/mods/new", RoomManageController, :addmod
    #get "/room/:roomname/removeuser/:username", RoomManageController, :removeuser
    #get "/room/:roomname/removemod/:username", RoomManageController, :removemod

    # ROOM -> POST
    get "/r/:room/new_post", PostController, :new
    get "/r/:room/comments/:hash/:title", PostController, :post
    get "/r/:room/comments/:hash/:title/view/:mode", PostController, :post
    get "/r/:room/comments/:hash/", PostController, :post
    get "/r/:room/comments/:hash/view/:mode", PostController, :post
    get "/r/:room/comments/:hash/:title/focus/:focushash", PostController, :comment
    get "/r/:room/comments/:hash/focus/:focushash", PostController, :comment

    # USER
    post "/u/session/new", UserController, :new
    get "/u/session/new", UserController, :index
    get "/u/session/delete", UserController, :delete
    get "/u/:username", UserController, :profile
    get "/u/:username/settings", UserController, :settings
  end
end
