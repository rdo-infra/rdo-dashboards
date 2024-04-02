require 'yaml'
require 'dashing'

configure do
  config = YAML.load_file('/etc/rdo-dashboards.conf')

  set :auth_token, config['auth_token']

  helpers do
    def protected!
     # Put any authentication code you want in here.
     # This method is run before accessing any resource.
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application

