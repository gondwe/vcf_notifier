# Advanced Email Configuration Guide

This guide shows how to use VcfNotifier's advanced email features for sophisticated email handling in your application.

## Basic Configuration

In your `config/config.exs`:

```elixir
config :vcf_notifier,
  email_provider: :smtp,  # or :sendgrid, :mailgun, etc.
  email_opts: [
    sender_name: "Your App Name",
    sender_email: "noreply@yourapp.com",
    default_subject: "Notification from Your App"
  ]

# Provider-specific configuration
config :vcf_notifier, :providers,
  smtp: [
    relay: "localhost", 
    port: 1025,
    username: "", 
    password: "",
    ssl: false, 
    tls: :never, 
    auth: :never
  ],
  sendgrid: [
    api_key: System.get_env("SENDGRID_API_KEY")
  ],
  mailgun: [
    api_key: System.get_env("MAILGUN_API_KEY"),
    domain: System.get_env("MAILGUN_DOMAIN")
  ]
```

## Creating Custom Mailers

### 1. Define a Mailer Module

```elixir
defmodule MyApp.Emails.WelcomeMailer do
  use VcfNotifier.Email.Generator
  
  @impl true
  def build_email(%{"user_id" => user_id} = params) do
    # Fetch user data (example)
    user = MyApp.Accounts.get_user!(user_id)
    
    %{
      subject: "Welcome to MyApp, #{user.name}!",
      email: user.email,
      name: user.name,
      html_body: render_welcome_html(user),
      text_body: render_welcome_text(user),
      custom_args: %{
        user_id: user.id,
        category: "welcome",
        template: "welcome_v2"
      }
    }
  end
  
  @impl true
  def prepare_attachments(%{"include_welcome_package" => true} = params) do
    user = MyApp.Accounts.get_user!(params["user_id"])
    
    %{
      filename: "welcome_package.pdf",
      data: MyApp.PDFGenerator.create_welcome_package(user),
      content_type: "application/pdf"
    }
  end
  
  def prepare_attachments(_), do: nil
  
  # Private functions for rendering templates
  defp render_welcome_html(user) do
    # Use Phoenix templates, EEx, or any templating system
    MyAppWeb.EmailView.render("welcome.html", user: user)
  end
  
  defp render_welcome_text(user) do
    MyAppWeb.EmailView.render("welcome.txt", user: user)
  end
end
```

### 2. Send Emails with Context

```elixir
# Single email with context
VcfNotifier.Email.send_with_context(
  MyApp.Emails.WelcomeMailer,
  %{
    "user_id" => 123,
    "include_welcome_package" => true
  }
)

# Bulk emails with context  
users_data = [
  %{"user_id" => 123, "include_welcome_package" => true},
  %{"user_id" => 124, "include_welcome_package" => false},
  %{"user_id" => 125, "include_welcome_package" => true}
]

VcfNotifier.Email.send_bulk_with_context(
  MyApp.Emails.WelcomeMailer, 
  users_data
)
```

## Advanced Use Cases

### Order Confirmation Emails

```elixir
defmodule MyApp.Emails.OrderConfirmationMailer do
  use VcfNotifier.Email.Generator
  
  @impl true
  def build_email(%{"order_id" => order_id}) do
    order = MyApp.Orders.get_order_with_items!(order_id)
    
    %{
      subject: "Order Confirmation ##{order.number}",
      email: order.customer_email,
      name: order.customer_name,
      html_body: render_order_html(order),
      text_body: render_order_text(order),
      custom_args: %{
        order_id: order.id,
        category: "order_confirmation",
        order_total: order.total_amount
      }
    }
  end
  
  @impl true  
  def prepare_attachments(%{"order_id" => order_id}) do
    order = MyApp.Orders.get_order!(order_id)
    
    %{
      filename: "invoice_#{order.number}.pdf",
      data: MyApp.InvoiceGenerator.create_pdf(order),
      content_type: "application/pdf"
    }
  end
end
```

### Password Reset Emails

```elixir
defmodule MyApp.Emails.PasswordResetMailer do
  use VcfNotifier.Email.Generator
  
  @impl true
  def build_email(%{"user_id" => user_id, "reset_token" => token}) do
    user = MyApp.Accounts.get_user!(user_id)
    reset_url = MyAppWeb.Router.Helpers.auth_url(MyAppWeb.Endpoint, :reset_password, token)
    
    %{
      subject: "Reset your MyApp password",
      email: user.email,
      name: user.name,
      html_body: """
      <p>Hello #{user.name},</p>
      <p>You requested a password reset. Click the link below:</p>
      <p><a href="#{reset_url}">Reset Password</a></p>
      <p>This link expires in 1 hour.</p>
      """,
      text_body: """
      Hello #{user.name},
      
      You requested a password reset. Visit this link:
      #{reset_url}
      
      This link expires in 1 hour.
      """,
      custom_args: %{
        user_id: user.id,
        category: "password_reset",
        token_hash: :crypto.hash(:sha256, token) |> Base.encode16()
      }
    }
  end
end
```

## Integration with Phoenix Controllers

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  
  def create(conn, %{"user" => user_params}) do
    case MyApp.Accounts.create_user(user_params) do
      {:ok, user} ->
        # Send welcome email asynchronously
        VcfNotifier.Email.send_with_context(
          MyApp.Emails.WelcomeMailer,
          %{"user_id" => user.id, "include_welcome_package" => true}
        )
        
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user))
        
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
```

## Monitoring and Tracking

The context-based emails automatically include tracking information in the `custom_args` field, which can be used for:

- Email delivery tracking
- User engagement analytics  
- A/B testing different email templates
- Debugging email issues

## Error Handling

```elixir
case VcfNotifier.Email.send_with_context(MyApp.Emails.WelcomeMailer, params) do
  {:ok, job} ->
    Logger.info("Welcome email queued for user #{params["user_id"]}")
    
  {:error, reason} ->
    Logger.error("Failed to queue welcome email: #{inspect(reason)}")
    # Handle error (maybe show user message, retry, etc.)
end
```

## Benefits of Context-Based Emails

1. **Separation of Concerns**: Email logic is separate from business logic
2. **Reusability**: Mailer modules can be reused across different parts of your app
3. **Testability**: Easy to test email content and logic independently
4. **Flexibility**: Can include complex business logic, database queries, file generation
5. **Tracking**: Built-in support for tracking and analytics
6. **Templates**: Integrate with any templating system (Phoenix, EEx, etc.)
