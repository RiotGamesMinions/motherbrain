module MotherBrain
  class ApiClient
    # @author Jamie Winsor <jamie@vialstudios.com>
    class JobResource < ApiClient::Resource
      def active
        json_get("/jobs/active.json")
      end

      def list
        json_get('/jobs.json')
      end

      # @param [String] id
      #   a Job uuid
      def show(id)
        json_get("/jobs/#{id}.json")
      end
    end
  end
end
