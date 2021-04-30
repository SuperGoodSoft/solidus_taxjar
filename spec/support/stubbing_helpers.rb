module StubbingHelpers
  def stub_taxjar_client
    instance_spy(SuperGood::SolidusTaxJar::API).tap do |taxjar|
      allow(SuperGood::SolidusTaxJar::API).to receive(:new).and_return(taxjar)
    end
  end
end

RSpec.configure do |config|
  config.include StubbingHelpers
end
