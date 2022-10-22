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

  # def encrypt(key, iv, data) do
  #   str = "data-to-be-encrypted"
  #   iv = :crypto.strong_rand_bytes(16)

  #   # ct = cipher_text
  #   # t = tag
  #   # iv = initialization_vector
  #   clear_text = "yellow_angel"
  #   cipher_text = "QTEyOEdDTQ.WKl9j-f4mXR8Vq4estVD-plz43PlbyLQy6tqNVPVDr2HsnHhh5JY-G7yaik.SfZ7LvA7-r4CjYRC.FatLJBshZFXmMjjrHWFOqJ1ZQ5Bg3OmxU7IpQDuvS8BFzep1-65R2_FA6NHFDYGEiOf8tw.1GEDDgBMQMP0M8UwsxYnAg"
  #   auth_data = ""
  #   key = "z9Yin50yoO0PunNqIUaxglAhahlooQ8aSOQrwqPSbmI="
  #   s = "5BSeTh0nsOm5dCgKxhT/Oa5sCR2vIKo9AKc8uEsSgvg"

  #   ExCrypto.decrypt(aes_256_key, auth_data, init_vec, cipher_text, cipher_tag)
  #   :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, str, "", true)
  # end

  def test do
    aes_256_key = "14h8UtHByEDHf1bGC5wVhIox/O2QMrhh5DZncDu/33A=" |> Base.decode64!()
    auth_data = "FC9ea0YiEubLo8jxkNZwdymKhz1qSbIlQKLTaJuc7lE" |> Base.decode64!(padding: false)
    clear_text = "yellow_angel"

    # payload = "QTEyOEdDTQ.xVsUkVaCHSVRAqHIjmVgMSA0pW-kWkt-UxpLrD0xll6XJjuGikrBDMxab8U.bKd3wX5Ife-aP1Tt.A3wd7Wv0ReKqDl3KnoEhY6kKS-W8CN44ZRzsEpH2PgcO6Dw4hnZnWsjTo8z50sraJQP-lA.E9zS-poZ3PPX4UQCwMURlw"
    a_token = "QTEyOEdDTQ.xVsUkVaCHSVRAqHIjmVgMSA0pW-kWkt-UxpLrD0xll6XJjuGikrBDMxab8U.bKd3wX5Ife-aP1Tt.A3wd7Wv0ReKqDl3KnoEhY6kKS-W8CN44ZRzsEpH2PgcO6Dw4hnZnWsjTo8z50sraJQP-lA.E9zS-poZ3PPX4UQCwMURlw"
    {_, jwe} = JOSE.JWE.expand(a_token)

    # iv = "?"
    # cipher_text = "?"
    # cipher_tag = "?"
    # MiniTeller.Client.Token

    decrypted_payload = JOSE.JWE.block_decrypt(encryption_key_private, encrypted_payload) |> elem(0)
JOSE.JWS.verify(signing_key, decrypted_payload) |> elem(0)


    ExCrypto.decrypt(aes_256_key, auth_data, jwe["iv"], jwe["ciphertext"], jwe["tag"])
  end

  # def decrypt_a_token(token, key) do
  #   key = Base.decode64!(key) |> Jason.decode!()
  #   key
  #   # decrypt(token, key["key"])
  # end

  # def decrypt(ciphertext, key) do
  #   secret_key = Base.decode64!(key)
  #   ciphertext = Base.decode64!(ciphertext)

  #   <<iv::binary-16, tag::binary-16, ciphertext::binary>> = ciphertext

  #   :crypto.crypto_one_time_aead(:aes_gcm, key, iv, "yellow_angel", ciphertext, true)

  # end

  defp generate_f_token(message),
    do: :crypto.hash(:sha256, message) |> Base.encode64(padding: false)
end


# clear_text = "my-clear-text"
# auth_data = "my-auth-data"
# {:ok, aes_256_key} = ExCrypto.generate_aes_key(:aes_256, :bytes)
# {:ok, {_ad, payload}} = ExCrypto.encrypt(aes_256_key, auth_data, clear_text)
# {init_vec, cipher_text, cipher_tag} = payload
# {:ok, val} = ExCrypto.decrypt(aes_256_key, auth_data, init_vec, cipher_text, cipher_tag)
# assert(val == clear_text)
# true
