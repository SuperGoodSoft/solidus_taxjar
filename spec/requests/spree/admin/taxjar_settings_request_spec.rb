require 'spec_helper'

RSpec.describe 'Admin TaxJar Settings', :type => :request do
  before { login_as create :admin_user }

  describe "PUT #update" do

    subject { put spree.admin_taxjar_settings_path }

    it do
      expect(subject).to eq(200)
    end
  end
end
