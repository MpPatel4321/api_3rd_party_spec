require 'uri'
require 'json'
require 'net/http'
require 'byebug'

class AsanaApi
  API_ENDPOINT = 'https://app.asana.com/api/1.0/'.freeze
  TOKEN = '1/1204892460316154:9d9c0f18d242721303ed8511113d5e11'.freeze

  class << self
    def create_project(params)
      url = get_url('projects')

      get_response(url, post_request(url), params)
    end

    def create_section(project_gid, params)
      url = get_url("projects/#{project_gid}/sections")

      get_response(url, post_request(url), params)
    end

    def get_section(section_gid)
      url = get_url("sections/#{section_gid}")

      get_response(url, get_request(url))
    end

    def get_workspaces
      url = get_url("workspaces")

      get_response(url, get_request(url))
    end

    def create_task(params)
      url = get_url("tasks")

      get_response(url, post_request(url), params)
    end

    def update_task(task_gid, params)
      url = get_url("tasks/#{task_gid}")

      request = Net::HTTP::Put.new(url)
      get_response(url, request, params)
    end

    def get_url(end_point)
      URI("#{API_ENDPOINT}#{end_point}") 
    end

    def get_request(url)
      Net::HTTP::Get.new(url)
    end

    def post_request(url)
      Net::HTTP::Post.new(url)
    end

    def get_response(url, request, params = {})
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request['Authorization'] = "Bearer #{TOKEN}"
      request['Content-Type'] = 'application/json'
      request.body = JSON.dump(params)

      response = https.request(request)

      { data: JSON.parse(response.body), message: response.message, status_code: response.code }
    end
  end
end

# params = {
#   "data": {
#     "current_status": {
#       "color": "yellow",
#       "text": "The project is moving forward according to plan...",
#       "html_text": "<body>The project <strong>is</strong> moving forward according to plan...</body>",
#       "title": "Status Update - Jun 15"
#     },
#     "team": "1204892461522561"
#   }
# }
# p AsanaApi.create_project(params)

# params = {
#   "data": {
#     "name": "Next Actions"
#   }
# }
# p AsanaApi.create_section(1204892377662438, params)

# p AsanaApi.get_section(1204894009803251)

# params = {
#   "data": {
#     "name": "Next Section"
#   }
# }

# p AsanaApi.update_section(1204894009803251, params)


  # p AsanaApi.create_task(params)

# params = {
#   "data": {
#     "workspace": "1204892461522559"
#   }
# }
# p AsanaApi.get_workspaces
# p AsanaApi.create_task(params)

# params = {
#   "data": {
#     "name": "test Task"
#   }
# }

# p AsanaApi.update_task(1204915313884890, params)