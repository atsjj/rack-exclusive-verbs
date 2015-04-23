require 'spec_helper'
require 'rack/mock'
require 'rack/exclusive_verbs'

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

  it 'has a version number' do
    expect(Rack::ExclusiveVerbs.VERSION).not_to be nil
  end
end
