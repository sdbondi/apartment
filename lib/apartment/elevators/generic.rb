module Apartment
  module Elevators
    #   Provides a rack based db switching solution based on request
    #
    class Generic

      def initialize(app, processor = nil)
        @app = app
        @processor = processor || method(:parse_database_name)
      end

      def call(env)
        request = Rack::Request.new(env)

        # Exclude some requests from schema switching e.g. assets
        unless Apartment.exclude_request_regex && request.path =~ Apartment.exclude_request_regex
          database = @processor.call(request)

          if database
            Apartment::Database.switch database 
          else
            return handle_not_found(env)
          end
        end

        @app.call(env)
      end

      def parse_database_name(request)
        raise "Override"
      end

      def handle_not_found(env)
        # Just continue
        @app.call(env)
      end
    end
  end
end
