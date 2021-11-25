require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::Settings do
  describe "is valid" do
    subject { taxjar_settings.valid? }

    let(:taxjar_settings) { create(:taxjar_settings) }

    it "is valid" do
      expect(subject).to be_truthy
    end
  end
end
