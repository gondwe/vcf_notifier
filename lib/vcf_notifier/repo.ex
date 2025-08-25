defmodule VcfNotifier.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :vcf_notifier,
    adapter: Ecto.Adapters.Postgres
end
