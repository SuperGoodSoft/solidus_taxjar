require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::CachedApi do
  describe ".nexus_regions" do
    subject { instance.nexus_regions }

    let(:instance) { described_class.new(api: dummy_api) }

    let(:dummy_api) do
      instance_double(SuperGood::SolidusTaxjar::Api)
    end

    let(:nexus_region) { ::Taxjar::NexusRegion.new(region: "California") }

    before do
      allow(dummy_api).to receive(:nexus_regions).and_return(
        [nexus_region]
      )
    end

    it "makes a request to the TaxJar API" do
      subject
      expect(dummy_api).to have_received(:nexus_regions)
    end

    it "returns a list of nexus regions" do
      expect(subject).to contain_exactly(nexus_region)
    end

    context "when nexus regions cached" do
      before do
        Rails.cache.write(:nexus_regions, [nexus_region])
      end

      it "doesn't make a request to the TaxJar API" do
        subject
        expect(dummy_api).to_not have_received(:nexus_regions)
      end

      it "returns a list of nexus regions" do
        expect(subject).to contain_exactly(nexus_region)
      end

      context "with refresh true" do
        subject { instance.nexus_regions(refresh: true) }

        it "makes a request to the TaxJar API" do
          subject
          expect(dummy_api).to have_received(:nexus_regions)
        end

        it "returns a list of nexus regions" do
          expect(subject).to contain_exactly(nexus_region)
        end
      end
    end
  end
end
