require 'rails_helper'

RSpec.describe StorageProviderPreviewSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:storage_provider) }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      is_expected.to have_key('name')
      is_expected.to have_key('description')
      expect(subject['id']).to eq(resource.id)
      expect(subject['name']).to eq(resource.display_name)
      expect(subject['description']).to eq(resource.description)
    end
  end
end
