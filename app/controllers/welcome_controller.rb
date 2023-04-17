class WelcomeController < ApplicationController
    def index
    end
    def trigger_job
        HelloJob.perform_later
        redirect_to other_job_done_path
    end
end