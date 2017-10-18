# name: warstage
# about: warstage integration plugin
# version: 0.9.1
# authors: Felix Ungman
# url: https://github.com/nikodil/userauth

enabled_site_setting :warstage_enabled

PLUGIN_NAME ||= "warstage".freeze

after_initialize do

  #ApplicationController.class_eval do
  #  before_filter :ensure_embeddable
  #  def ensure_embeddable
  #    origin = SiteSetting.openwar_origin
  #    domains = SiteSetting.openwar_domains
  #    response.headers['X-Frame-Options'] = "ALLOW-FROM #{origin}"
  #    response.headers['Content-Security-Policy'] = "default-src 'self' #{domains};" +
  #      " script-src 'self' #{domains} data: 'unsafe-inline' 'unsafe-eval';" +
  #      " style-src 'self' #{domains} 'unsafe-inline';" +
  #      " img-src 'self' #{domains} data:;" +
  #      " font-src 'self' #{domains} data:;" +
  #      " media-src 'self' #{domains} data:;" +
  #      " frame-ancestors 'self' #{domains};"
  #  end
  #end

  module ::Warstage
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace Warstage
    end
  end

  require_dependency 'application_controller'

  class Warstage::UserController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    #before_filter :ensure_logged_in, except: [:token]

    def verify
      user = fetch_user_from_params(include_inactive: current_user.try(:staff?))
      user = nil unless user.confirm_password?(params[:password])
      render json: user_to_json(user)
    end

    def lookup
      user = if params[:email]
         User.find_by_email(params[:email])
      else
        fetch_user_from_params(include_inactive: current_user.try(:staff?))
      end
      render json: user_to_json(user)
    end

    def grant_badge
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
        {errors:["no user"]}
      end
    end
  end

  Warstage::Engine.routes.draw do
    get '/user/verify' => 'user#verify'
    get '/user/lookup' => 'user#lookup'
    get '/user/grant_badge' => 'user#grant_badge'
  end

  Discourse::Application.routes.append do
    mount ::Warstage::Engine, at: '/warstage'
  end

end
