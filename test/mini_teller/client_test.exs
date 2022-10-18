defmodule MiniTeller.ClientTest do
  use ExUnit.Case, async: true

  import Mox

  alias MiniTeller.Client
  #   @callback enroll() ::  {:ok, binary()}
  # @callback reauthenticate() :: {:ok, binary()}
  # @callback accounts() :: {:ok, binary()}
  # @callback transactions() :: {:ok, nil}

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "it can enroll" do
    expect(MiniTeller.Mock, :enroll, fn -> {:ok, nil} end)

    assert {:ok, _} = Client.enroll()
  end
end
