defmodule MiniTeller.Client.ParseError do
  @moduledoc """
    HTTP Error handling and logging
  """

  require Logger

  def call({:ok, %Tesla.Env{status: 400, body: body} = env}) do
    Logger.error("[teller_client] bad request: #{inspect(env)}")
    {:error, body["error"]}
  end

  def call({:ok, %Tesla.Env{status: 404, body: body} = env}) do
    # todo: handle device id has changed
    Logger.error("[teller_client] not found: #{inspect(env)}")
    {:error, body}
  end

  def call({:ok, :timeout}) do
    Logger.error("[teller_client] timeout")
    {:error, %{"code" => "timeout", "message" => "request timeout"}}
  end

  def call(error) do
    Logger.error("[teller_client] unexpected error: #{inspect(error)}")
    {:error, %{"code" => "unkown", "message" => "unexpected error"}}
  end
end
