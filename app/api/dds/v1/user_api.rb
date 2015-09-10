module DDS
  module V1
    class UserAPI < Grape::API
      desc 'api_token' do
        detail 'This allows a client to present an access token from a registred authentication service and get an api token'
        named 'api_token'
        failure [
          [200,'Success'],
          [401, 'Missing, or invalid Access Token']
        ]
      end
      params do
        requires :access_token
      end
      rescue_from Grape::Exceptions::ValidationErrors do |e|
        error_json = {
          "error" => 400,
          "reason" => "no access_token",
          "suggestion" => "you might need to login through an authenticaton service"#,
        }
        error!(error_json, 400)
      end
      rescue_from JWT::VerificationError do
        error!({
          error: 401,
          reason: 'invalid access_token',
          suggestion: 'token not properly signed'
        },401)
      end
      get '/user/api_token', root: false do
        token_info_params = declared(params)
        encoded_access_token = token_info_params[:access_token]
        if access_token = JWT.decode(encoded_access_token, Rails.application.secrets.secret_key_base)[0]
          auth_service = AuthenticationService.where(uuid: access_token['service_id']).first
          if auth_service
            authorized_user = auth_service.user_authentication_services.where(uid: access_token['uid']).first
            if authorized_user
              new_login_at = DateTime.now
              authorized_user.user.update_attribute(:last_login_at, DateTime.now)
            else
              new_user = User.create(
                id: SecureRandom.uuid,
                username: access_token['uid'],
                etag: SecureRandom.hex,
                email: access_token['email'],
                display_name: access_token['display_name'],
                first_name: access_token['first_name'],
                last_login_at: DateTime.now,
                last_name: access_token['last_name']
              )
              authorized_user = auth_service.user_authentication_services.create(
                uid: access_token['uid'],
                user: new_user
              )
            end
            {'api_token' => authorized_user.api_token}
          else
            error!({
              error: 401,
              reason: 'invalid access_token',
              suggestion: 'authenticaton service not recognized'
            }, 401)
          end
        end
      end

      desc 'users' do
        detail 'This allows a client to get a list of users, with an optional filter'
        named 'users'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized']
        ]
      end
      params do
        optional :last_name_begins_with, type: String, desc: 'list users whose last name begins with this string'
        optional :first_name_begins_with, type: String, desc: 'list users whose first name begins with this string'
        optional :display_name_contains, type: String, desc: 'list users whose full name contains this string'
      end
      get '/users', root: 'results' do
        authenticate!
        query_params = declared(params, include_missing: false)
        users = []
        if query_params[:last_name_begins_with]
          users = User.where(
            "last_name like ?",
            "#{query_params[:last_name_begins_with]}%").order(last_name: :asc).all
        elsif query_params[:display_name_contains]
          users = User.where(
            "display_name like ?",
            "%#{query_params[:display_name_contains]}%").order(last_name: :asc).all
        elsif query_params[:first_name_begins_with]
          users = User.where(
            "first_name like ?",
            "#{query_params[:first_name_begins_with]}%").order(last_name: :asc).all
        else
          users = User.order(last_name: :asc).all
        end
        users
      end
    end
  end
end
