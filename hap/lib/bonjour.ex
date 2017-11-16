defmodule HAP.Bonjour do
  # @moduledoc false

  use GenServer
  require Logger

  def start_link(_args) do
    Logger.warn "#### STARTING BONJOUR ####"
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_state) do
    {:ok, _} = Registry.register(Nerves.Udhcpc, "wlan0", [])
    {:ok, %{:pids => []}}
  end

  def handle_info({Nerves.Udhcpc, :bound, %{ifname: "wlan0"} = data}, state) do
    Logger.debug "DNS BOUND! #{inspect(data)}"

    state = advertise(state)
    {:noreply, state}
  end

  def handle_info(stuff, state) do
    Logger.warn "Found weird stuff: #{inspect(stuff)} and shit #{inspect(state)}"
    {:noreply, state}
  end

  defp clear_advertisements(state) do
    Enum.each(state.pids, &(:dnssd.stop(&1)))
    %{state | :pids => []}
  end

  defp advertise(state) do
    state = clear_advertisements(state)

    name = accessory_name()
    {:ok, hap_pid} = :dnssd.register(name, "_hap._tcp", 80, txt())
    {:ok, http_pid} = :dnssd.register(name, "_http._tcp", 80)

    %{state | :pids => [hap_pid, http_pid]}
  end

  defp txt do
    pairing_id = "11:22:33:44:55:66"
    model_name = "happi"
    status_flag = status_flag()
    config_number = current_config()
    feature_flag = 0 # Only MFi certified accessories should set this to 1. 
    ["c#=#{config_number}", "ff=#{feature_flag}", "id=#{pairing_id}", "md=#{model_name}", "pv=1.0", "s#=1", "sf=#{status_flag}", "ci=2"]
  end

  @doc """
    The user assigned accessory name.
  """
  def accessory_name() do
    # We should probably store this in the System Registry.
    "Patrick's Accessory"
  end

  @doc """
    Returns the current config number.
    Defined in HAP-Specification-Non-Commercial-Version.pdf page 69
  """
  @spec current_config() :: Integer
  def current_config() do
    map = SystemRegistry.match(%{state: %{hap: %{config: :_}}})
    map[:state][:hap][:config] || 1
  end

  @doc """
    Call whenever the hap characteristics we are advertising change.
  """
  def increment_config() do
    SystemRegistry.update([:state, :hap, :config], current_config() + 1)
  end

  @doc """
    Update to return 0 when paired.
    Defined in HAP-Specification-Non-Commercial-Version.pdf page 70
  """
  def status_flag do
    "1"
  end
end