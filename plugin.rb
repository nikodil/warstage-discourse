# name: warstage
# about: warstage integration plugin
# version: 1.0.0
# authors: Felix Ungman
# url: ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/warstage-discourse

enabled_site_setting :warstage_enabled

PLUGIN_NAME ||= "warstage".freeze

after_initialize do

  module ::Warstage
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace Warstage
    end
  end

  require_dependency 'application_controller'

  class Warstage::UserController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    def verify
      user = nil
      if params[:apikey] == SiteSetting.warstage_apikey
        begin
          user = fetch_user_from_params(include_inactive: current_user.try(:staff?))
          user = nil unless user.confirm_password?(params[:password])
        rescue Discourse::NotFound
        end
      end
      render json: user_to_json(user)
    end

    def lookup
      user = nil
      if params[:apikey] == SiteSetting.warstage_apikey
        begin
          user = if params[:email]
             User.find_by_email(params[:email])
          else
            fetch_user_from_params(include_inactive: current_user.try(:staff?))
          end
        rescue Discourse::NotFound
        end
      end
      render json: user_to_json(user)
    end

    def user_to_json(user)
      if user
        badges = user.badges.map{|x| {id: x.id, name: x.name} if x.enabled}
        groups = user.groups.map{|x| {id: x.id, name: x.name}}
        {
          id: user.id,
          username: user.username,
          fullname: user.name,
          email: user.email,
          badges: badges,
          groups: groups,
          avatar_url: user.avatar_template.gsub('{size}', '45')
        }
      else
        {}
      end
    end
  end

  Warstage::Engine.routes.draw do
    get '/user/verify' => 'user#verify'
    get '/user/lookup' => 'user#lookup'
  end

  Discourse::Application.routes.append do
    mount ::Warstage::Engine, at: '/warstage'
  end

end
