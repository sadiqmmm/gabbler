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

  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GabblerWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/u/:username", PageController, :profile
    get "/u/:username/settings", PageController, :settings
    get "/about", PageController, :about
    get "/tos", PageController, :tos

    get "/h/:room", RoomController, :house
    get "/r/:room", RoomController, :room
    get "/r/:room/view/:mode", RoomController, :room
    get "/room/new", RoomController, :new

    #get "/room/:roomname/manage", RoomManageController, :manage
    #get "/room/:roomname/manage/mods", RoomManageController, :manage_mods
    #post "/room/:roomname/new", RoomManageController, :allowuser
    #post "/room/:roomname/manage/mods/new", RoomManageController, :addmod
    #get "/room/:roomname/removeuser/:username", RoomManageController, :removeuser
    #get "/room/:roomname/removemod/:username", RoomManageController, :removemod

    get "/r/:room/new_post", PostController, :new
    get "/r/:room/comments/:hash/:title", PostController, :post
    get "/r/:room/comments/:hash/:title/view/:mode", PostController, :post
    get "/r/:room/comments/:hash/", PostController, :post
    get "/r/:room/comments/:hash/view/:mode", PostController, :post
    get "/r/:room/comments/:hash/:title/focus/:focushash", PostController, :comment
    get "/r/:room/comments/:hash/focus/:focushash", PostController, :comment
  end
end
