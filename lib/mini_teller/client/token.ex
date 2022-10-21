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

  def encrypt(key) do
    str = "data-to-be-encrypted"
    iv = :crypto.strong_rand_bytes(16)

    :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, str, "", true)
  end

  def decrypt_a_token(token, key) do
    key = Base.decode64!(key) |> Jason.decode!()
    decrypt(token, key["key"])
  end

  def decrypt(ciphertext, key) do
    secret_key = Base.decode64!(key)
    ciphertext = Base.decode64!(ciphertext)

    <<iv::binary-16, tag::binary-16, ciphertext::binary>> = ciphertext

    :crypto.crypto_one_time_aead(:aes_gcm, key, iv, "yellow_angel", ciphertext, true)

  end

  defp generate_f_token(message),
    do: :crypto.hash(:sha256, message) |> Base.encode64(padding: false)
end
