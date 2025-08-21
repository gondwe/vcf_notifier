# Recommended Usage Examples

## Simple, Flexible Email Sending (Recommended Approach)

Here's how applications should use VcfNotifier for maximum flexibility:

### 1. Basic Email Sending

```elixir
# In your application code
defmodule MyApp.Emails do
  
  def send_welcome_email(user) do
    email = %VcfNotifier.Email{
      to: [user.email],
      from: "welcome@myapp.com",
      subject: "Welcome to MyApp, #{user.name}!",
      html_body: build_welcome_html(user),
      text_body: build_welcome_text(user)
    }
    
    # Send immediately
    VcfNotifier.Email.FlexibleService.send_now(email)
    
    # OR send asynchronously (recommended for web requests)
    VcfNotifier.Email.FlexibleService.send_async(email)
  end
  
  def send_order_confirmation(order) do
    email = %VcfNotifier.Email{
      to: [order.customer_email],
      from: "orders@myapp.com", 
      subject: "Order ##{order.number} Confirmed",
      html_body: MyApp.EmailTemplates.render("order_confirmation.html", order: order),
      attachments: [generate_invoice_pdf(order)]
    }
    
    VcfNotifier.Email.FlexibleService.send_async(email)
  end
  
  # Private helpers
  defp build_welcome_html(user) do
    # Use your existing template system
    MyApp.EmailTemplates.render("welcome.html", user: user)
  end
  
  defp build_welcome_text(user) do
    MyApp.EmailTemplates.render("welcome.txt", user: user)
  end
  
  defp generate_invoice_pdf(order) do
    %{
      filename: "invoice_#{order.number}.pdf",
      data: MyApp.PDFGenerator.create_invoice(order),
      content_type: "application/pdf"
    }
  end
end
```

### 2. Using Builder Functions for Bulk Operations

```elixir
defmodule MyApp.Emails do
  
  def send_newsletter_to_users(user_ids, newsletter_content) do
    # Define how to build each email
    builder = fn user_id ->
      user = MyApp.Accounts.get_user!(user_id)
      
      %VcfNotifier.Email{
        to: [user.email],
        from: "newsletter@myapp.com",
        subject: newsletter_content.subject,
        html_body: MyApp.EmailTemplates.render("newsletter.html", 
          user: user, 
          content: newsletter_content
        ),
        provider_options: %{
          category: "newsletter",
          user_id: user.id
        }
      }
    end
    
    # Send to all users with automatic queuing
    VcfNotifier.Email.FlexibleService.send_bulk_with_builder(builder, user_ids)
  end
  
  def send_password_reset_emails(reset_requests) do
    builder = fn %{user_id: user_id, reset_token: token} ->
      user = MyApp.Accounts.get_user!(user_id)
      reset_url = MyAppWeb.Router.Helpers.reset_url(MyAppWeb.Endpoint, :show, token)
      
      %VcfNotifier.Email{
        to: [user.email],
        from: "security@myapp.com",
        subject: "Reset your MyApp password",
        html_body: MyApp.EmailTemplates.render("password_reset.html", 
          user: user, 
          reset_url: reset_url
        ),
        text_body: MyApp.EmailTemplates.render("password_reset.txt", 
          user: user, 
          reset_url: reset_url
        )
      }
    end
    
    VcfNotifier.Email.FlexibleService.send_bulk_with_builder(builder, reset_requests)
  end
end
```

### 3. Integration with Phoenix Controllers

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  
  def create(conn, %{"user" => user_params}) do
    case MyApp.Accounts.create_user(user_params) do
      {:ok, user} ->
        # Send welcome email asynchronously - won't block the response
        Task.start(fn -> MyApp.Emails.send_welcome_email(user) end)
        
        conn
        |> put_flash(:info, "Account created! Check your email for welcome information.")
        |> redirect(to: Routes.user_path(conn, :show, user))
        
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end

defmodule MyAppWeb.OrderController do
  use MyAppWeb, :controller
  
  def create(conn, %{"order" => order_params}) do
    case MyApp.Orders.create_order(order_params) do
      {:ok, order} ->
        # Send confirmation email
        case MyApp.Emails.send_order_confirmation(order) do
          {:ok, _job} ->
            conn
            |> put_flash(:info, "Order placed! Confirmation email sent.")
            |> redirect(to: Routes.order_path(conn, :show, order))
            
          {:error, _reason} ->
            # Order was created but email failed - handle gracefully
            conn
            |> put_flash(:warning, "Order placed, but confirmation email failed. We'll retry shortly.")
            |> redirect(to: Routes.order_path(conn, :show, order))
        end
        
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
```

### 4. Testing Your Email Logic

```elixir
defmodule MyApp.EmailsTest do
  use ExUnit.Case
  
  # Test email building (pure functions - easy to test)
  test "builds welcome email correctly" do
    user = %MyApp.User{
      email: "test@example.com",
      name: "John Doe"
    }
    
    email = MyApp.Emails.build_welcome_email(user)
    
    assert email.to == ["test@example.com"]
    assert email.subject == "Welcome to MyApp, John Doe!"
    assert email.html_body =~ "Hello John Doe"
    assert email.from == "welcome@myapp.com"
  end
  
  # Mock the VcfNotifier calls for integration tests
  test "sends welcome email" do
    # Use Mox or similar to mock VcfNotifier
    expect(VcfNotifier.Email.FlexibleService, :send_async, fn email, _opts ->
      assert email.to == ["test@example.com"]
      {:ok, %Oban.Job{id: 123}}
    end)
    
    user = %MyApp.User{email: "test@example.com", name: "John"}
    assert {:ok, %Oban.Job{}} = MyApp.Emails.send_welcome_email(user)
  end
end
```

### 5. Configuration in your app

```elixir
# config/config.exs
config :vcf_notifier,
  email_provider: :smtp,
  email_opts: [
    sender_name: "MyApp",
    sender_email: "noreply@myapp.com"
  ]

# config/prod.exs  
config :vcf_notifier,
  email_provider: :sendgrid,
  providers: [
    sendgrid: [
      api_key: System.get_env("SENDGRID_API_KEY")
    ]
  ]
```

## Why This Approach?

1. **Your app controls email building** - use your existing templates, data access, etc.
2. **Library handles delivery** - reliable queuing, retries, provider management
3. **Easy to test** - email building is pure functions
4. **Flexible** - works with any template system or app structure
5. **Gradual adoption** - can migrate existing email systems piece by piece
6. **Performance** - async by default, efficient bulk operations

## Advanced: Context-Based Approach (Optional)

If you need the more complex context-based approach (like in your production examples), it's still available:

```elixir
# Define a mailer module
defmodule MyApp.Emails.WelcomeMailer do
  use VcfNotifier.Email.Generator
  
  @impl true
  def build_email(%{"user_id" => user_id}) do
    user = MyApp.Accounts.get_user!(user_id)
    %{
      subject: "Welcome!",
      email: user.email,
      name: user.name,
      html_body: render_template(user)
    }
  end
end

# Use it
VcfNotifier.Email.send_with_context(MyApp.Emails.WelcomeMailer, %{"user_id" => 123})
```

But for most applications, the flexible approach above is simpler and more maintainable.
