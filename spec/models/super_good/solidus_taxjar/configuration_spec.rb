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
end
