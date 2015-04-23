require 'ipaddr'
require 'set'

module Rack
  # Rack middleware implementing the IETF draft: "Host Metadata for the Web"
  # including support for Link-Pattern elements as described in the IETF draft:
  # "Link-based Resource Descriptor Discovery."
  #
  # Usage:
  #  use Rack::ExclusiveVerbs do
  #    allow only: '10.0.0.1', to: [:put, :post]
  #    allow only: '10.0.0.1', to: :post
  #    allow only: '10.0.0.1', to: :be_safe ## get, head, options, trace
  #    allow only: '10.0.0.1', to: :be_unsafe ## delete, patch, post, put
  #    allow range: '10.0.0.0/24', to: [:put, :post]
  #    allow range: '10.0.0.0/24', to: :post
  #    allow range: '10.0.0.0/24', to: :be_safe ## get, head, options, trace
  #    allow range: '10.0.0.0/24', to: :be_unsafe ## delete, patch, post, put
  #  end
  #
  # See also:
  #   http://tools.ietf.org/html/draft-nottingham-site-meta
  #   http://tools.ietf.org/html/draft-hammer-discovery
  #
  # TODO:
  #   ...
  #
  class ExclusiveVerbs
    def initialize(app, &block)
      @app = app
      @rules = {}
      instance_eval(&block)
    end

    def call(env)
      if is_allowed?(env)
        @app.call(env)
      else
        [403, {"Content-Type" => "text/plain"}, ["403 Forbidden"]]
      end
    end

    protected

    def is_allowed?(env)
      request = Rack::Request.new(env)

      verb = request.request_method.downcase.to_sym
      ip = IPAddr.new(request.ip)

      if @rules.has_key?(verb)
        return @rules[verb].any? { |rule| rule.include?(ip) }
      else
        return false
      end
    end

    def allow(config)
      options = {
        only: nil,
        range: nil,
        to: [:head, :get, :options, :trace]
      }.merge(config)

      compound_verbs = {
        be_safe: [:get, :head, :options, :trace],
        be_unsafe: [:delete, :patch, :post, :put]
      }

      # Use options[:only] as a syntax sugar, prefer options[:range]
      options[:range] ||= options[:only]

      # Replace options[:to] values of :be_unsafe or :be_safe with real verbs
      if compound_verbs.has_key?(options[:to])
        options[:to] = compound_verbs[options[:to]]
      end

      # Wrap options[:to] in an array, if only a symbol was passed
      unless options[:to].kind_of?(Array)
        options[:to] = [options[:to]]
      end

      options[:to].each do |verb|
        unless @rules.has_key?(verb.to_sym)
          @rules[verb.to_sym] = Set.new
        end

        ip = IPAddr.new(options[:range])
        @rules[verb.to_sym].add(ip)
      end
    end

    class << self
      def VERSION; "0.1.0"; end
    end
  end
end