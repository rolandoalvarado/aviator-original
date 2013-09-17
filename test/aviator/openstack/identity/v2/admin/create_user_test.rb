require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/identity/v2/admin/create_user' do

    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |params|
                  params[:name]     = 'this_doesnt_matter_with_this_test'
                  params[:password] = 'sample_passw0rd'
                end

      klass.new(session_data, &block)
    end


    def get_session_data
      session.send :auth_info
    end


    def helper
      Aviator::Test::RequestHelper
    end


    def klass
      @klass ||= helper.load_request('openstack', 'identity', 'v2', 'admin', 'create_user.rb')
    end


    def session
      unless @session
        @session = Aviator::Session.new(
          config_file: Environment.path,
          environment: 'openstack_admin'
        )
        @session.authenticate
      end

      @session
    end


    validate_attr :api_version do
      klass.api_version.must_equal :v2
    end


    validate_attr :anonymous? do
      klass.anonymous?.must_equal false
    end


    validate_attr :body do
      params = {
        name:      'username_example',
        password:  'user_password123',
        email:     'sample@email.com',
        tenant_id: 'sample_tenant_id',
        enabled:   true
      }

      body = {
        user: params
      }

      request = klass.new(get_session_data) do |p|
        params.each do |k,v|
          p[k] = params[k]
        end
      end

      body[:user][:tenantId] = body[:user].delete(:tenant_id)

      request.body.must_equal body
    end


    validate_attr :endpoint_type do
      klass.endpoint_type.must_equal :admin
    end


    validate_attr :headers do
      headers = { 'X-Auth-Token' => get_session_data[:access][:token][:id] }

      request = create_request

      request.headers.must_equal headers
    end


    validate_attr :http_method do
      create_request.http_method.must_equal :post
    end


    validate_attr :required_params do
      klass.required_params.must_equal [:name, :password]
    end


    validate_attr :optional_params do
      klass.optional_params.must_equal [:email, :enabled, :tenant_id]
    end


    validate_attr :url do
      session_data = get_session_data
      service_spec = session_data[:access][:serviceCatalog].find { |s| s[:type] == 'identity' }
      url = "#{ service_spec[:endpoints][0][:adminURL] }/users"

      request = create_request

      request.url.must_equal url
    end


    validate_response 'invalid param is provided' do
      service = session.identity_service

      response = service.request :create_user do |params|
        params[:name]     = 'username_123'
        params[:password] = 'password_123'
        params[:enabled]  = 'invalid-type'
      end

      # TODO: Update this test and cassette.
      #       Status should be 400 and with more user-friendly message
      #       This bug was fixed on commit 840a0758 in tag 2013.2.b1
      #       Unfortunately, I only have 2013.1 on my testing environment
      response.status.must_equal 500
      response.body.wont_be_nil
      response.headers.wont_be_nil
    end


    validate_response 'params are valid' do
      # must be hardcoded so as not to inadvertently alter random resources
      # in case the corresponding cassette is deleted
      tenant_id = '13aad0de723c43e785b8b7ae7e5ea07a'

      service = session.identity_service

      response = service.request :create_user do |params|
        params[:name]      = 'username_123'
        params[:password]  = 'password_123'
        params[:email]     = 'dump@foo.com'
        params[:enabled]   = true
        params[:tenant_id] = tenant_id
      end

      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:user].wont_be_nil
      response.headers.wont_be_nil
    end


  end

end
