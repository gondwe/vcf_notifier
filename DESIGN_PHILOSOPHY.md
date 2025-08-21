# Library Design Philosophy: Context Management

## The Question: Who Should Handle Email Context?

When building a notification library, there's a critical design decision: should the library manage email context (templates, data fetching, business logic) or should it focus purely on delivery?

## Two Approaches Compared

### Approach 1: Library-Managed Context (More Rigid)

```elixir
# What we initially built - library handles everything
defmodule MyApp.Emails.WelcomeMailer do
  use VcfNotifier.Email.Generator  # Library-defined behavior
  
  @impl true
  def build_email(%{"user_id" => user_id}) do
    user = MyApp.Accounts.get_user!(user_id)  # App fetches data
    %{
      subject: "Welcome!",
      email: user.email,
      html_body: render_template(user)  # App renders template
    }
  end
end

# Usage - library resolves context
VcfNotifier.Email.send_with_context(MyApp.Emails.WelcomeMailer, %{"user_id" => 123})
```

**Problems:**
- Forces specific module structure
- String-based module resolution (`String.to_existing_atom`)
- Hard to test email logic in isolation
- Library becomes opinionated about app structure
- Difficult to integrate with existing email systems

### Approach 2: Application-Managed Context (More Flexible)

```elixir
# Library provides building blocks, app controls the flow
defmodule MyApp.Emails do
  def build_welcome_email(user_id) do
    user = MyApp.Accounts.get_user!(user_id)
    
    %VcfNotifier.Email{
      to: [user.email],
      from: "welcome@myapp.com",
      subject: "Welcome #{user.name}!",
      html_body: MyApp.Templates.render("welcome.html", user: user),
      text_body: MyApp.Templates.render("welcome.txt", user: user)
    }
  end
  
  def send_welcome_email(user_id, opts \\ []) do
    user_id
    |> build_welcome_email()
    |> VcfNotifier.Email.send_async(opts)
  end
end

# Or even more flexible with builder functions
def send_welcome_emails(user_ids) do
  builder = fn user_id -> MyApp.Emails.build_welcome_email(user_id) end
  VcfNotifier.Email.send_bulk_with_builder(builder, user_ids)
end
```

**Benefits:**
- App controls email building completely
- Easy to test (`MyApp.Emails.build_welcome_email/1` is pure)
- Works with existing app structure
- Library focuses on what it does best: delivery
- No magic string-to-module resolution

## Recommended Approach: Keep Library Simple

Based on your production examples and library design best practices, I recommend **Approach 2**. Here's why:

### 1. Single Responsibility Principle
The library should focus on:
- ✅ Reliable email delivery
- ✅ Queue management  
- ✅ Provider abstraction
- ✅ Retry logic
- ❌ NOT: Template rendering, data fetching, business logic

### 2. Integration Flexibility
Apps often have existing:
- Template systems (Phoenix views, EEx, Mustache, etc.)
- Email builders
- Data access patterns
- Testing strategies

A rigid library forces them to change or duplicate their patterns.

### 3. Testability
```elixir
# Easy to test - pure function
test "builds welcome email correctly" do
  user = %User{email: "test@example.com", name: "John"}
  email = MyApp.Emails.build_welcome_email(user)
  
  assert email.to == ["test@example.com"]
  assert email.subject == "Welcome John!"
  assert email.html_body =~ "Welcome John"
end

# Library handles delivery - can be mocked/stubbed
test "sends welcome email" do
  expect(VcfNotifier.Email, :send_async, fn _email, _opts -> {:ok, %Oban.Job{}} end)
  assert {:ok, _job} = MyApp.Emails.send_welcome_email(123)
end
```

## Recommended Library Interface

Here's what the library should provide:

```elixir
defmodule VcfNotifier.Email do
  # Core delivery functions
  def send_now(%VcfNotifier.Email{} = email)
  def send_async(%VcfNotifier.Email{} = email, opts \\ [])
  def send_at(%VcfNotifier.Email{} = email, datetime, opts \\ [])
  def send_in(%VcfNotifier.Email{} = email, delay_seconds, opts \\ [])
  
  # Flexible bulk sending with app-provided builders
  def send_bulk_with_builder(builder_function, params_list, opts \\ [])
  
  # Simple bulk sending for identical emails
  def send_bulk([%VcfNotifier.Email{}, ...], opts \\ [])
end
```

## How Apps Should Structure Emails

### Option 1: Simple Functions (Recommended for most cases)
```elixir
defmodule MyApp.Emails do
  def welcome_email(user) do
    %VcfNotifier.Email{
      to: [user.email],
      from: app_sender(),
      subject: "Welcome to MyApp!",
      html_body: render_template("welcome.html", user: user),
      text_body: render_template("welcome.txt", user: user)
    }
  end
  
  def order_confirmation_email(order) do
    %VcfNotifier.Email{
      to: [order.customer_email],
      subject: "Order ##{order.number} Confirmed",
      html_body: render_template("order_confirmation.html", order: order),
      attachments: [generate_invoice_pdf(order)]
    }
  end
  
  # Send functions
  def send_welcome_email(user), do: VcfNotifier.Email.send_async(welcome_email(user))
  def send_order_confirmation(order), do: VcfNotifier.Email.send_async(order_confirmation_email(order))
end
```

### Option 2: Module-per-Email (For complex emails)
```elixir
defmodule MyApp.Emails.WelcomeEmail do
  def build(user) do
    %VcfNotifier.Email{
      to: [user.email],
      from: "welcome@myapp.com",
      subject: build_subject(user),
      html_body: build_html(user),
      text_body: build_text(user),
      attachments: build_attachments(user)
    }
  end
  
  def send(user), do: VcfNotifier.Email.send_async(build(user))
  def send_at(user, datetime), do: VcfNotifier.Email.send_at(build(user), datetime)
  
  # Private helpers for complex email building...
end
```

### Option 3: Behavior-Based (For very complex systems)
```elixir
defmodule MyApp.EmailBehavior do
  @callback build(any()) :: VcfNotifier.Email.t()
  @callback send(any()) :: {:ok, Oban.Job.t()} | {:error, term()}
end

defmodule MyApp.Emails.WelcomeEmail do
  @behaviour MyApp.EmailBehavior
  # Implementation...
end
```

## Migration Strategy

If you have the complex context-based system, here's how to migrate:

1. **Keep the complex system as an optional add-on**
2. **Make the simple interface the primary API**
3. **Document both approaches**
4. **Let users choose based on their needs**

This gives you:
- Simple API for 80% of use cases
- Complex system for sophisticated needs
- Easy migration path
- Maximum flexibility

## Conclusion

**Recommendation: Simplify the library core, make context management optional.**

The library should be like a good tool - powerful but not prescriptive. Focus on reliable delivery and let applications handle their own email building patterns.
