require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::Configuration do
  describe "is valid" do
    subject { taxjar_configuration.valid? }

    let(:taxjar_configuration) { create(:taxjar_configuration) }

    it "is valid" do
      expect(subject).to be_truthy
    end
  end

  describe "#preferred_reporting_enabled" do
    subject { taxjar_configuration.preferred_reporting_enabled }

    let(:taxjar_configuration) { create(:taxjar_configuration) }

    it "has the default value" do
      expect(subject).to be_falsey
    end
  end

  describe "#preferred_reporting_enabled=" do
    subject { taxjar_configuration.update(preferred_reporting_enabled: true) }

    let(:taxjar_configuration) { create(:taxjar_configuration) }

    it "sets the value" do
      expect { subject }.to change { taxjar_configuration.reload.preferred_reporting_enabled }.from(false).to(true)
    end
  end

  describe ".default" do
    subject { described_class.default }

    context "configuration exists" do
      let!(:taxjar_configuration) { create :taxjar_configuration }

      it "returns the default configuration" do
        expect(subject).to eq(taxjar_configuration)
      end
    end

    context "configuration doesn't exist" do
      it "creates the default config" do
        expect { subject }.to change { described_class.count }.from(0).to(1)
      end

      it "returns a config" do
        expect(subject).to be_instance_of(described_class)
      end

      context "calling default more than once" do
        it "creates only one config" do
          described_class.default
          expect { subject }.to_not change { described_class.count }.from(1)
        end
      end
    end
  end
end
