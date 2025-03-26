# SidekiqRetryStrategy

SidekiqRetryStrategy is a Ruby gem designed to provide a customizable retry strategy for handling operations that may fail temporarily. With this gem, you can easily integrate retry logic into your application, ensuring that transient errors are retried efficiently.

## Installation

Install the gem and add it to your application's Gemfile by executing:

```bash
$ bundle add sidekiq_retry_strategy
```

If Bundler is not being used to manage dependencies, install the gem manually by executing:

```bash
$ gem install sidekiq_retry_strategy
```

## Compatibility

This gem is compatible with Rails 8.0 and later. For earlier versions of Rails, use version `0.1.x` of this gem.

## Usage

### Basic Usage Example

Here’s an example of how you can use the SidekiqRetryStrategy in a service class:

```ruby
require 'sidekiq_retry_strategy'

class ExampleService
  include SidekiqRetryStrategy::Strategies::DefaultRetry

  def perform_operation
    # Your operation logic here
  end
end

service = ExampleService.new
service.perform_operation
```

This will retry the block of code up to 5 times with depending on which retry strategy is selected.

### Overriding Retry Options in Workers

You can override the retry options directly in your worker by defining the `set_retry_options` in sidekiq_options. This allows you to specify custom retry parameters for specific workers.

```ruby
class CouponCampaignExpiryReminder < ApplicationJob
  sidekiq_options queue: :campaigns, retry: true, set_retry_options: { max_retries: 2, delays: [100, 200] }

  include SidekiqRetryStrategy::Strategies::BusinessAdminActivityRetry

  def perform(*args*)
    # Your operation logic here
  end
end
```

### Graphic Representation

The following diagram illustrates the retry logic implemented by SidekiqRetryStrategy:

```mermaid
graph TD
    A[Start Operation] --> B{Operation Successful?}
    B -- Yes --> C[End]
    B -- No --> D{Retries Left?}
    D -- Yes --> E[Wait for Delay] --> A
    D -- No --> F[Raise Error]
```

## Development

After checking out the repository, set up the development environment by running:

```bash
$ bin/setup
```

Run the tests using:

```bash
$ rake spec
```

To experiment with the gem in an interactive environment, run:

```bash
$ bin/console
```

To install this gem onto your local machine, use:

```bash
$ bundle exec rake install
```

To release a new version:

1. Update the version number in `version.rb`.
2. Run:

```bash
$ bundle exec rake release
```