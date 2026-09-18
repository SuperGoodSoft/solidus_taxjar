module SuperGood
  module SolidusTaxjar
    module RequestOverride
      def build_http_client
        if SuperGood::SolidusTaxjar.logging_enabled
          super.use(logging: {logger: SuperGood::SolidusTaxjar.logger})
        else
          super
        end
      end

      def set_http_timeout
        super
        timeouts = @http_timeout.compact
        @http_timeout = timeouts.empty? ? :null : timeouts
      end

      Taxjar::API::Request.prepend(self)
    end
  end
end
