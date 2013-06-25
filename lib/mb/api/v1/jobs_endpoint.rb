module MotherBrain::API
  class V1
    class JobsEndpoint < MB::API::Endpoint
      rescue_from MB::JobNotFound do |ex|
        rack_response(ex.to_json, 404, "Content-type" => "application/json")
      end

      namespace 'jobs' do
        desc "list all jobs (completed and active)"
        get do
          job_manager.list
        end

        desc "list all active jobs"
        get 'active' do
          job_manager.active
        end

        desc "find and return the Job with the given ID"
        params do
          requires :job_id, type: String, desc: "job id"
        end
        get ':job_id' do
          find_job!(params[:job_id])
        end
      end
    end
  end
end
