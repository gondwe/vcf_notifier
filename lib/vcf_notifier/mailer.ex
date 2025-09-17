# Backwards-compatible simple Bamboo-only mailer used internally by the library by default.
defmodule VcfNotifier.Mailer do

  alias VcfNotifier.Backends.MailBackend
  @moduledoc false
  # Default internal mailer uses Bamboo via the macro backend
  use MailBackend, otp_app: :vcf_notifier, adapter: Bamboo.LocalAdapter, backend: :bamboo
end
