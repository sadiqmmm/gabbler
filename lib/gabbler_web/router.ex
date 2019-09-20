defmodule GabblerWeb.Router do
  use GabblerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
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

    get "/h/:room", PageController, :house
    get "/r/:room", PageController, :room
    get "/r/:room/view/:mode", PageController, :room
    get "/r/:room/comments/:hash/:title", PageController, :comments
    get "/r/:room/comments/:hash/:title/view/:mode", PageController, :comments
    get "/r/:room/comments/:hash/:title/focus/:focushash", PageController, :comments
    get "/r/:room/comments/:hash/", PageController, :comments
    get "/r/:room/comments/:hash/view/:mode", PageController, :comments
    get "/r/:room/comments/:hash/focus/:focushash", PageController, :comments
    get "/room/new", RoomController, :new
    get "/room/:roomname/edit", RoomController, :edit

    get "/room/:roomname/manage", RoomManageController, :manage
    get "/room/:roomname/manage/mods", RoomManageController, :manage_mods
    post "/room/:roomname/new", RoomManageController, :allowuser
    post "/room/:roomname/manage/mods/new", RoomManageController, :addmod
    get "/room/:roomname/removeuser/:username", RoomManageController, :removeuser
    get "/room/:roomname/removemod/:username", RoomManageController, :removemod

    get "/r/:room/newpost", RoomPostController, :new
    post "/r/:room/new", RoomPostController, :create
    get "/h/:room/newpost", RoomPostController, :new
    post "/h/:room/newpost", RoomPostController, :create

    post "/post/:hash/comment", PostController, :comment
    post "/post/mod/:hash/comment", PostController, :mod_delete_comment
  end
end
