# Background Jobs with Sidekiq

> This is a sample application that demonstrates how to use [Sidekiq]("http://sidekiq.org") to perform background jobs in a Rails application.

## Getting Started
#### What is Background Jobs?
Background jobs are tasks that are performed outside of the request-response cycle. They are useful for tasks that take a long time to complete and would cause the user to wait if they were performed synchronously. Examples of background jobs include sending emails, processing uploaded files, and long running calculations.
In Ruby on Rails, a background job is a process that runs asynchronously in the background, separate from the main request-response cycle of a web application. Background jobs allow you to offload long-running, resource-intensive tasks from the web server to a separate process, which can run on the same machine or a different machine.

Background jobs are commonly used to perform tasks that are not time-sensitive, such as sending email, generating reports, processing large datasets, or performing periodic maintenance tasks. By running these tasks in the background, you can ensure that the web application remains responsive and available to handle new requests.

In Ruby on Rails, there are several popular libraries for implementing background jobs, such as DelayedJob, Resque, Sidekiq, and Active Job. These libraries provide a simple and consistent API for defining, enqueueing, and executing background jobs, and often support advanced features such as retries, priorities, and job dependencies.

#### What is Sidekiq?
There are two giants in this space : delayed_jobs (sometimes known as "DJ"), and Sidekiq. Sidekiq is more well-known, maintained, and documented, I would advise here to choose Sidekiq for any new Rails application.
Sidekiq is a simple, efficient background processing for Ruby. It uses threads to handle many jobs at the same time in the same process. It does not require Rails but will integrate tightly with Rails to make background processing dead simple.

### Prerequisites
To run this application, you will need to have the following installed on your machine:
* Ruby (latest version recommended)
* Rails
* Redis

### Create a fresh new Rails app 
```bash
$ rails new sidekiq-demo --force --database=postgresql --minimal

$ cd sidekiq-demo
```
#### Create a default controller
```bash
$ rails g controller welcome index
```
#### Add a root route
```ruby
# config/routes.rb
Rails.application.routes.draw do
    get "welcome/index"
  root to: 'welcome#index'
end
```
#### Add a default view
```erb
<!-- app/views/welcome/index.html.erb -->
<h1>Welcome to Sidekiq Demo</h1>
```
#### # Create database and schema.rb
```bash
$ rails db:create
$ rails db:migrate
```

Then open application.rb and uncomment line 6 as follow :
```ruby
# config/application.rb
require "active_job/railtie" # <== Uncomment
```
Then create the parent Class of all jobs :
```bash
$ rails g job application_job
```
```ruby
# inside app/jobs/application_job.rb
  class ApplicationJob < ActiveJob::Base
  end
```
>Side note We created the Rails app with the --minimal flag, so that you can discover clearly what is needed to run a job. With the default install, active_job/railtie is already uncommented, and the parent Class of all jobs already exists.

#### Add Sidekiq and Redis gem
```ruby
# Gemfile
gem 'redis'
gem 'sidekiq'
```
Then run bundle install
```bash
$ bundle install
```
Then add the following line inside application.rb :
```ruby
# inside config/application.rb
# ...
class Application < Rails::Application
    config.active_job.queue_adapter = :sidekiq
# ...
```
#### Create a new file under app/jobs/hello_world_job.rb
```ruby
# inside app/jobs/hello_world_job.rb
class HelloWorldJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Simulates a long, time-consuming task
    sleep 5
    # Will display current time, milliseconds included
    p "hello from HelloWorldJob #{Time.now().strftime('%F - %H:%M:%S.%L')}"
  end

end
```
Modify routes.rb as follow :
```ruby
# inside config/routes.rb
Rails.application.routes.draw do
  get "welcome/index"

  # route where any visitor require the helloWorldJob to be triggered
  post "welcome/trigger_job"

  # where visitor are redirected once job has been called
  get "other/job_done"

  root to: "welcome#index"
end
```
#### Create app/controllers/other_controller.rb
```ruby
# inside app/controllers/other_controller.rb
class OtherController < ApplicationController

  def job_done
  end

end
```
#### Create app/views/other/job_done.html.erb
```erb
<!-- inside app/views/other/job_done.html.erb -->
<h1>Job was called</h1>
```
#### Create app/controllers/welcome_controller.rb
```ruby
# inside app/controllers/welcome_controller.rb
class WelcomeController < ApplicationController

  def index
  end

  def trigger_job
    # Trigger the job
    HelloWorldJob.perform_later
    # Redirect to the other controller
    redirect_to other_job_done_path
  end

end
```
#### Now our job is ready to be called from the initial view :
```erb
<!-- inside app/views/welcome/index.html.erb -->
<h1>Welcome to Sidekiq Demo</h1>
<%= form_tag welcome_trigger_job_path, method: :post do %>
  <%= submit_tag "Trigger Job" %>
<% end %>
```

#### And the call will happen inside the controller, like this :
```ruby
# inside app/controllers/welcome_controller.rb
class WelcomeController < ApplicationController

  def index
  end

  def trigger_job
    # Trigger the job
    HelloWorldJob.perform_later
    # Redirect to the other controller
    redirect_to other_job_done_path
  end

end
```
#### Add a Procfile.dev
```ruby
# inside Procfile.dev
web: bin/rails s
worker: bundle exec sidekiq -C config/sidekiq.yml
```
#### Add a sidekiq.yml
```ruby
# inside config/sidekiq.yml
    development:
  :concurrency: 5

    production:
    :concurrency: 10

    :max_retries: 1

    :queues:
    - default
```
#### And finally add the sidekiq initializer here : config/initializers/sidekiq.rb
```ruby
# inside config/initializers/sidekiq.rb

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
end
Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
end
```

#### Start the server
```bash
$ foreman start -f Procfile.dev
```
#### Open a new terminal and run redis-server
```bash
$ redis-server
```
#### Open a new terminal and run sidekiq
```bash
$ sidekiq
```

Thanks for reading, I hope you enjoyed this tutorial. If you have any questions, please feel free to ask.

### References
* [Bootrails](https://www.bootrails.com/blog/rails-sidekiq-tutorial/)



