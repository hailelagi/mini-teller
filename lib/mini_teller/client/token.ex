defmodule MiniTeller.Client.Token do
  @moduledoc """
    Token managment
  """
  alias MiniTeller.Client.Session

  def create_f_token(spec, req_id) do
    spec
    |> Base.decode64!()
    |> parse_f_token_spec(req_id)
    |> generate_f_token()
  end

  def parse_f_token_spec(spec, req_id) do
    [_, spec] = String.split(spec, "sha-256-b64-np")
    format = String.slice(spec, 1..-2)

    [seperator | _] =
      String.split(format, ~r/[^[:punct:]]+/)
      |> Enum.filter(fn s -> s != "-" and s != "" end)

    String.split(format, seperator)
    |> Enum.map(&order_hash(&1, req_id))
    |> Enum.join(seperator)
  end

  defp order_hash(spec, req_id) do
    %{device_id: device_id} = Session.info()

    case spec do
      "device-id" -> device_id
      "last-request-id" -> req_id
      "username" -> Application.get_env(:mini_teller, :username)
      "api-key" -> Application.get_env(:mini_teller, :api_key)
    end
  end

  def decrypt_account(enc_key, %{"body" => %{"data" => data}} = env) do
    s_token = Tesla.get_header(env, "s-token")
    key = enc_key |> Base.decode64!() |> Jason.decode!()
    aes_256_key = key["key"] |> Base.decode64!()
    iv = data["accounts"]["checking"]["mask"]
    clear_text = Application.get_env(:mini_teller, :username)

    {:ok, {_ad, payload}} = ExCrypto.encrypt(aes_256_key, s_token, iv, clear_text)

    {init_vec, cipher_text, cipher_tag} = payload

    payload
  end

  defp generate_f_token(message),
    do: :crypto.hash(:sha256, message) |> Base.encode64(padding: false)
end
