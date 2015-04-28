Background Worker
=================

Provides a worker abstraction with an additional status channel.

Start by making a worker class which extends from BackgroundWorker::Base

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

Then, when you want to perform a task in the background, use
klass#perform_in_background which exists in Base:

   worker_id = MyWorker.perform_in_background(:my_task, message: "hello!")

By default this will call your instance method in the foreground -- you have to
provide an enqueueing method with the #enqueue method like so:

    BackgroundWorker.enqueue_with do |klass, method_name, options|
      Resque.enqueue(klass, method_name, options)
    end

This is independent of the status reporting which (currently) always uses Redis.

The worker_id you are returned can be used to get the status, and
whether the worker has finished successfully, failed, or in progress:

    state = BackgroundWorker.get_state_of(worker_id)

The state is represented by a hash with the following keys:

    message: Reported message
    detailed_message: Detailed version of above when provided
    status: :successful, :failed, or null if still processing
    completed: True if report_failed, report_successful called (or worker
               finished without exception -- which calls report_successful)
    data: Arbitrary data returned by worker method on success or report_failed

If an exception is raised, the worker will call #report_failed with the
details. You can provide a callback with
BackgroundWorker#after_exception

# INSTALLATION

gem install background_worker

or add to your Gemfile:
gem 'background_worker'

