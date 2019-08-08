defmodule HAP.Bonjour do
  # @moduledoc false
  require Logger

  defstruct [:name, :service, :txt, port: 80]

  defmodule Advertiser do
    @moduledoc """
    A behavior to be implemented by the host application to allow
    advertising via mdns without forcing a particualr mdns client.
    """
    @callback update_advertisement_info([%{}]) :: :ok | {:error, String.t()}

    def update_advertisement_info(_info) do
      {:error, "Unimplemented function."}
    end
  end

  @default_advertiser Advertiser
  def advertise() do
    config = Application.get_env(:hap, __MODULE__, [])
    bonjour = config[:advertiser] || @default_advertiser

    bonjour.update_advertisement_info(advertisement_info())
  end

  def advertisement_info() do
    [
      %HAP.Bonjour{name: accessory_name(), service: "_hap._tcp", port: 80, txt: txt()},
      %HAP.Bonjour{name: accessory_name(), service: "_http._tcp", port: 80, txt: [""]}
    ]
  end

  def txt do
    pairing_id = HAP.Pairing.Impl.pairing_id()
    model_name = accessory_name()
    status_flag = status_flag()
    config_number = current_config()
    # Only MFi certified accessories should set this to 1.
    feature_flag = 0

    [
      "c#=#{config_number}",
      "ff=#{feature_flag}",
      "id=#{pairing_id}",
      "md=#{model_name}",
      "pv=1.0",
      "s#=1",
      "sf=#{status_flag}",
      "ci=2"
    ]
  end

  @doc """
    The user assigned accessory name.
  """
  def accessory_name() do
    config = Application.get_env(:hap, __MODULE__, [])
    config[:hostname] || "Happi"
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
