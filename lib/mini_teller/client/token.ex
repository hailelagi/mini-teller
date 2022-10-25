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

  # def test do
  #   key = "a/V3H5mRfbQgRiebJxjyZbOl1hvEe3UcK7fCIxRR9SM=" |> Base.decode64!()
  #   auth_data = "375/f1NkAHtjkefBlYtHDCg93SxU8MgJtuEji69IlDY" |> Base.decode64!(padding: false)
  #   clear_text = "yellow_angel"

  #   a_token =
  #     "QTEyOEdDTQ.IH7T0BBvDwNsU7GOawkYixM2DPPcujEeYhokRCRAMi595gyi8QrEi7lBq18.sW5eRvWVyoXzkQeb.kFrHojaQXJw3q3wSRfb-SXnyHqK0f-010SHlLAn6jCmOudz1G5XVJt9oSQp1XEcUkU-q1g.s0ij-K3Z4MQ3iCAZaWg0UQ"

  #   {:ok, {_ad, payload}} = ExCrypto.encrypt(key, auth_data, clear_text)
  #   {init_vec, cipher_text, cipher_tag} = payload

  #   IO.inspect(init_vec, charlists: :as_lists)
  #   jwk = JOSE.JWK.from_oct(auth_data)

  #   JOSE.JWE.block_decrypt(jwk, a_token)
  #   # ExCrypto.decrypt(key, auth_data, init_vec, cipher_text, cipher_tag)
  # end

  def decrypt_account(key) do
    key = key |> Base.decode64!() |> Jason.decode!()

    # <<iv::binary-16, tag::binary-16, ciphertext::binary>> = ciphertext

    # {:ok, :crypto.crypto_one_time_aead(:aes_gcm, key, iv, "yellow_angel", ciphertext, true)}
    {:ok , key}
  end

  defp generate_f_token(message),
    do: :crypto.hash(:sha256, message) |> Base.encode64(padding: false)
end
