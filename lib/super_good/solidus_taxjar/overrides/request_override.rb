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

      Taxjar::API::Request.prepend(self)
    end
  end
end
