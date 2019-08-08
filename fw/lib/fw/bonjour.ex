defmodule Fw.BonjourAdvertiser do
  @moduledoc """
  A HAP.Bonjour.Advertiser behaviour implementation for
  advertising via mdns.
  """
  require Logger
  use GenServer

  @behaviour HAP.Bonjour.Advertiser

  def start_link(_args) do
    Logger.debug("Starting Bonjour Advertiser")
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_state) do
    Logger.debug("Init Bonjour Advertiser")

    state = %{:info => HAP.Bonjour.advertisement_info()}
    # Nerves.NetworkInterface.interfaces()
    # |> Enum.filter(&Enum.member?(@interfaces, &1))
    # |> Enum.each(&Registry.register(Nerves.NetworkInterface, &1, []))
    state = Map.put(state, :pids, [])
    state = advertise(state)

    {:ok, state}
  end

  def handle_info({Nerves.NetworkInterface, :ifchanged, %{is_up: true} = data}, state) do
    Logger.debug("IS_UP: true! #{inspect(data)}")

    state = advertise(state)
    {:noreply, state}
  end

  def handle_info({Nerves.NetworkInterface, :ifchanged, %{is_up: false} = data}, state) do
    Logger.debug("IS_UP: false! #{inspect(data)}")

    state = clear_advertisements(state)
    {:noreply, state}
  end

  def handle_call({:update_advertisement_info, info}, _from, state) do
    Logger.debug("UPDATE_ADVERTISEMENT_INFO #{inspect(info)}")

    state =
      %{state | :info => info}
      |> clear_advertisements
      |> advertise

    {:reply, :ok, state}
  end

  defp clear_advertisements(state) do
    Enum.each(state.pids, &:dnssd.stop(&1))

    %{state | :pids => []}
  end

  defp advertise(state) do
    Logger.debug("ADVERTISING #{inspect(state.info)}")

    new_pids =
      Enum.map(state.info, &Nerves.Dnssd.register(&1.name, &1.service, &1.port, &1.txt))
      |> Enum.map(fn info ->
        {:ok, pid} = info
        pid
      end)

    pids = state.pids ++ new_pids
    %{state | :pids => pids}
  end

  def update_advertisement_info(info) do
    Logger.debug("calling :update_advertisement_info")
    :ok = GenServer.call(__MODULE__, {:update_advertisement_info, info})
  end
end
