# Background Worker

[![Gem Version](https://badge.fury.io/rb/background_worker.svg)](http://badge.fury.io/rb/background_worker)
[![Build Status](https://github.com/sealink/background_worker/workflows/Build%20and%20Test/badge.svg?branch=master)](https://github.com/sealink/background_worker/actions)

Provides a worker abstraction with an additional status channel.

Start by making a worker class which extends from BackgroundWorker::Base

```ruby
    class MyWorker < BackgroundWorker::Base
      def my_task(options={})
        report_progress('Starting')
        if options[:message].blank?
          report_failed("No message provided")
          return
        end

        puts options[:message]
        {original_message: message}
      end
    end
```

Then, when you want to perform a task in the background, use
klass#perform_in_background which exists in Base:

```ruby
    worker_id = MyWorker.perform_in_background(:my_task, message: "hello!")
```

# Backgrounded

By default this will call your instance method in the foreground -- you have to
provide an #enqueue_with configuration like so:

```ruby
    BackgroundWorker.configure(
      enqueue_with: -> klass, method_name, options {
        Resque.enqueue(klass, method_name, options)
      }
    )
```

This is independent of the status reporting which (currently) always uses Redis.

# Getting the status

The worker_id you are returned can be used to get the status and
whether the worker has finished successfully, failed, or is still in progress:

```ruby
    state = BackgroundWorker.get_state_of(worker_id)
```

The state is represented by a hash with the following keys:

| key                                                          | description                                                          |
| ------------------------------------------------------------ | -------------------------------------------------------------------- |
| message                                                      | Reported message                                                     |
| detailed_message                                             | Detailed version of above when provided                              |
| status                                                       | :successful, :failed, or null if still processing                    |
| completed                                                    | True if report_failed, report_successful called (or worker           |
| finished without exception -- which calls report_successful) |
| data                                                         | Arbitrary data returned by worker method on success or report_failed |

If an exception is raised, the worker will call #report_failed with the
details. You can provide a callback with #after_exception in the config.

# Installation

Add to your Gemfile:

```ruby
    gem 'background_worker'
```

# Release

To publish a new version of this gem the following steps must be taken.

- Update the version in the following files
  ```
    CHANGELOG.md
    lib/background_worker/version.rb
  ```
- Create a tag using the format v0.1.0
- Follow build progress in GitHub actions
