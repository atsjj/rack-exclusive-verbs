require 'spec_helper'
require 'rack/mock'
require 'rack/exclusive_verbs'
require 'socket'

class RequestApp
  def initialize(&block)
    app = Rack::Builder.new do
      use Rack::Lint
      use Rack::ExclusiveVerbs, &block
      run Rack::MockApp
    end

    @request = Rack::MockRequest.new(app)
  end

  def from(ip, config)
    options = {
      as: :get,
    }.merge(config)

    method = options[:as].id2name.upcase

    @request.request(method, '/', { "REMOTE_ADDR" => ip })
  end
end

shared_examples 'single rule' do
  let(:request_only_to_get) do
    RequestApp.new do
      allow only: '10.0.0.1', to: :get
    end
  end

  let(:request_only_to_get_and_post) do
    RequestApp.new do
      allow only: '10.0.0.1', to: [:get, :post]
    end
  end

  let(:request_range_to_get) do
    RequestApp.new do
      allow range: '10.0.0.0/24', to: :get
    end
  end

  let(:request_range_to_get_and_post) do
    RequestApp.new do
      allow range: '10.0.0.0/24', to: [:get, :post]
    end
  end

  it 'allow only: "10.0.0.1", to: :get' do
    response = request_only_to_get.from ip, as: :get
    expect(response.status).to eq(status)
  end

  it 'allow only: "10.0.0.1", to: [:get, :post]' do
    response = request_only_to_get_and_post.from ip, as: :get
    expect(response.status).to eq(status)

    response = request_only_to_get_and_post.from ip, as: :post
    expect(response.status).to eq(status)
  end

  it 'allow range: "10.0.0.0/24", to: :get' do
    response = request_range_to_get.from ip, as: :get
    expect(response.status).to eq(status)
  end

  it 'allow range: "10.0.0.0/24", to: [:get, :post]' do
    response = request_range_to_get_and_post.from ip, as: :get
    expect(response.status).to eq(status)

    response = request_range_to_get_and_post.from ip, as: :post
    expect(response.status).to eq(status)
  end
end

describe Rack::ExclusiveVerbs do
  let!(:ok_status) { 200 }
  let!(:not_ok_status) { 403 }

  context 'requests from: "10.0.0.1" should be HTTP 200' do
    let!(:ip) { '10.0.0.1' }
    let!(:status) { 200 }

    include_examples 'single rule'
  end

  context 'requests from: "192.168.0.1" should be HTTP 403' do
    let!(:ip) { '192.168.0.1' }
    let!(:status) { 403 }

    include_examples 'single rule'
  end

  context 'with resolver returning ["10.0.0.1", "10.0.0.2"]' do
    let!(:request_only_with_resolver_to_get) do
      RequestApp.new do
        resolver { ['10.0.0.1', '10.0.0.2'] }
        allow only: '10.0.0.1', to: :get
      end
    end

    it 'request from: "192.168.0.1" with rule `allow only: "10.0.0.1", to: :get` should be HTTP 200' do
      response = request_only_with_resolver_to_get.from '192.168.0.1', as: :get
      expect(response.status).to eq(ok_status)
    end

    it 'request from: "10.0.0.1" with rule `allow only: "10.0.0.1", to: :get` should be HTTP 200' do
      response = request_only_with_resolver_to_get.from '10.0.0.1', as: :get
      expect(response.status).to eq(ok_status)
    end
  end

  context 'with resolver returning ["10.9.0.105", "169.254.254.1", "192.168.2.4", "127.0.0.1"]' do
    let!(:request_ranges_with_resolver_to_get) do
      RequestApp.new do
        resolver { ['10.5.0.105', '169.254.254.1', '192.168.2.4', '127.0.0.1'] }
        allow range: '0.0.0.0/8',     to: :be_safe
        allow range: '128.0.0.0/16',  to: :be_safe
        allow range: '192.0.0.0/24',  to: :be_safe
        allow range: '10.0.0.0/8',    to: :be_safe
        allow range: '172.16.0.0/12', to: :be_safe
        allow range: '10.5.0.0/24',   to: :be_unsafe
      end
    end

    it 'get request from: "0:0:0:0:0:0:0:1" with multiple range rules `"0/8", "128/16", "192/24", "10/8", "172.16/12", to: :be_safe` should be HTTP 200' do
      response = request_ranges_with_resolver_to_get.from '0:0:0:0:0:0:0:1', as: :get
      expect(response.status).to eq(ok_status)
    end

    it 'get request from: "10.9.0.105" with multiple range rules `"0/8", "128/16", "192/24", "10/8", "172.16/12", to: :be_safe` should be HTTP 200' do
      response = request_ranges_with_resolver_to_get.from '10.9.0.105', as: :get
      expect(response.status).to eq(ok_status)
    end

    it 'post request from: "10.5.0.140" with multiple range rules `"0/8", "128/16", "192/24", "10/8", "172.16/12", to: :be_safe` should be HTTP 200' do
      response = request_ranges_with_resolver_to_get.from '10.9.0.105', as: :post
      expect(response.status).to eq(ok_status)
    end
  end

  context 'with re-implemented `Rack::Request.ip` resolver' do
    let!(:request_only_with_resolver_to_get) do
      RequestApp.new do
        resolver { |request| request.ip }
        allow only: '10.0.0.1', to: :get
      end
    end

    it 'request from: "192.168.0.1" with rule `allow only: "10.0.0.1", to: :get` should be HTTP 403' do
      response = request_only_with_resolver_to_get.from '192.168.0.1', as: :get
      expect(response.status).to eq(not_ok_status)
    end

    it 'request from: "10.0.0.1" with rule `allow only: "10.0.0.1", to: :get` should be HTTP 200' do
      response = request_only_with_resolver_to_get.from '10.0.0.1', as: :get
      expect(response.status).to eq(ok_status)
    end
  end

  it 'has a version number' do
    expect(Rack::ExclusiveVerbs.VERSION).not_to be nil
  end
end
