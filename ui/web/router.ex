defmodule Ui.Router do
  use Ui.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :hap_pairing do
    plug :accepts, ["application/pairing+tlv8"]
    plug Ui.Plugs.DecodeTLV
  end

  scope "/", Ui do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end
  
  scope "/", Ui do
    pipe_through :hap_pairing

    post "/pair-setup", PairSetupController, :pair_setup
    post "/pair-verify", PairVerifyController, :pair_verify
    post "/pairings", PairingsController, :pairings
  end
end
