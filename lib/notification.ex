defmodule Notification do
  @moduledoc """
  Convenience alias for VcfNotifier.

  This module provides a cleaner API by automatically proxying all public functions
  from VcfNotifier. Any new functions added to VcfNotifier will automatically be
  available through this module.

  ## Examples

      # These are equivalent:
      Notification.send(%{type: :email, to: "user@example.com", subject: "Hello", body: "World"})
      VcfNotifier.send(%{type: :email, to: "user@example.com", subject: "Hello", body: "World"})

      # Async sending:
      Notification.send_async(notification)

      # Scheduled sending:
      Notification.send_in(notification, 3600)  # 1 hour delay
      Notification.send_at(notification, ~U[2024-01-15 10:00:00Z])

      # Bulk email:
      Notification.send_bulk_email(["user1@example.com", "user2@example.com"], "Subject", "Body")
  """

  # Macro to automatically proxy all public functions from VcfNotifier
  defmacro __using__(_opts) do
    quote do
      import Notification
    end
  end

  # Get all exported functions from VcfNotifier and create proxy functions
  for {function_name, arity} <- VcfNotifier.__info__(:functions) do
    args = Macro.generate_arguments(arity, __MODULE__)

    def unquote(function_name)(unquote_splicing(args)) do
      apply(VcfNotifier, unquote(function_name), unquote(args))
    end
  end
end
