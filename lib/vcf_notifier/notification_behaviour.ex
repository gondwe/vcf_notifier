defmodule VcfNotifier.NotificationBehaviour do
  @moduledoc """
  Behaviour for notification types (email, sms, etc).
  Implement this behaviour for each notification type module.
  """

  @callback send(map()) :: {:ok, any()} | {:error, any()}
  @callback send_async(map(), keyword()) :: {:ok, any()} | {:error, any()}
  @callback send_at(map(), DateTime.t(), keyword()) :: {:ok, any()} | {:error, any()}
  @callback send_in(map(), integer(), keyword()) :: {:ok, any()} | {:error, any()}
end
