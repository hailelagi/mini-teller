defmodule MiniTeller.TokenTest do
  use ExUnit.Case, async: true

  alias MiniTeller.Client.{Session, Token}

  setup do
    Session.cache_device("FAKEDEVICE")
    :ok
  end

  describe "it parses the f-token spec correctly" do
    test "with a pattern" do
      spec = "sha-256-b64-np(api-key+username+last-request-id)"

      assert "FakeApiKey?+test_user+test_id" == Token.parse_f_token_spec(spec, "test_id")
    end

    test "with a repeating pattern" do
      spec = "sha-256-b64-np(device-id--username--last-request-id)"

      assert "FAKEDEVICE--test_user--test_id" == Token.parse_f_token_spec(spec, "test_id")
    end

    test "spec with special random character" do
      sep = Enum.random(["--", "++", "??", "@@", "##", "%", "-", "+", "?", "@", "#", "%"])
      fields = field() <> sep <> field() <> sep <> field()
      fake_spec = "sha-256-b64-np(#{fields})"

      token = Base.encode64(fake_spec) |> Token.create_f_token("test_id")
      assert is_binary(token)
    end
  end

  defp field, do: Enum.random(["device-id", "username", "api-key", "last-request-id"])
end
