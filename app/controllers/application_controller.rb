class ApplicationController < ActionController::API
  include ActionController::Cookies

  before_action :set_active_storage_url_options

  private

  def default_url_options
    return {} unless request&.host

    { host: request.host, port: request.port, protocol: request.scheme }
  end

  def set_active_storage_url_options
    return unless request.respond_to?(:host)

    ActiveStorage::Current.url_options = {
      host: request.host,
      port: request.port,
      protocol: request.scheme
    }
  end
end
