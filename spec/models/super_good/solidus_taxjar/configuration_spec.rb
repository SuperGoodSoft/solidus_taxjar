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

    context "reporting_enabled_at is set in the past" do
      let(:taxjar_configuration) { create(:taxjar_configuration, preferred_reporting_enabled_at_integer: DateTime.now.to_i) }

      it "is true" do
        expect(subject).to be_truthy
      end
    end

    context "reporting_enabled_at is set in the future" do
      let(:taxjar_configuration) { create(:taxjar_configuration, preferred_reporting_enabled_at_integer: (DateTime.now + 1.day).to_i) }

      it "is false" do
        expect(subject).to be_falsy
      end
    end
  end

  describe "#preferred_reporting_enabled_at" do
    subject { taxjar_configuration.preferred_reporting_enabled_at }

    let(:taxjar_configuration) { create(:taxjar_configuration, preferred_reporting_enabled_at_integer: datetime_integer) }
    let(:datetime_integer) { 1675116247 }

    it "parses the integer datetime" do
      expect(subject).to eq DateTime.parse("Mon, 30 Jan 2023 22:04:07 +0000")
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
