$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rack/exclusive_verbs'

module Rack
  class MockApp
    def initialize(app, &block)
      @app = app
    end

    def self.call(env)
      res = Response.new
      res.write('Mocking...')
      res.finish
    end
  end
end
