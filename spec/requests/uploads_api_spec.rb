require 'rails_helper'

describe DDS::V1::UploadsAPI do
  include_context 'with authentication'

  let(:chunk) { FactoryGirl.create(:chunk, :swift, number: 1) }
  let(:upload) { chunk.upload }
  let(:project) { upload.project }
  let!(:storage_provider) { upload.storage_provider }
  let(:other_upload) { FactoryGirl.create(:upload) }
  let(:user) { FactoryGirl.create(:user) }
  let(:upload_stub) { FactoryGirl.build(:upload) }
  let(:chunk_stub) { FactoryGirl.build(:chunk) }

  let(:resource_class) { Upload }
  let(:resource_serializer) { UploadSerializer }
  let!(:resource) { upload }
  let!(:resource_permission) { FactoryGirl.create(:project_permission, user: current_user, project: upload.project) }

  describe 'Uploads collection' do
    let(:url) { "/api/v1/projects/#{project.id}/uploads" }

    #List file uploads for a project
    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a listable resource' do
        let(:unexpected_resources) { [
          other_upload
        ] }
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/notexists_projectid/uploads" }
        let(:resource_class) { 'Project' }
      end

      it_behaves_like 'a paginated resource' do
        let(:expected_total_length) { project.uploads.count }
        let(:extras) { FactoryGirl.create_list(:upload, 5, project_id: project.id) }
      end

      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { project }
      end
    end

    #Initiate a chunked file upload for a project
    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
      let(:called_action) { "POST" }
      let!(:payload) {{
        name: upload_stub.name,
        content_type: upload_stub.content_type,
        size: upload_stub.size,
        hash: {
          value: upload_stub.fingerprint_value,
          algorithm: upload_stub.fingerprint_algorithm
        }
      }}

      it_behaves_like 'a creatable resource' do
        it 'should set creator' do
          is_expected.to eq(expected_response_status)
          expect(new_object.creator_id).to eq(current_user.id)
        end
        
        it 'should set fingerprint_value' do
          is_expected.to eq(expected_response_status)
          expect(new_object.fingerprint_value).to eq(payload[:hash][:value])
        end
        
        it 'should set fingerprint_algorithm' do
          is_expected.to eq(expected_response_status)
          expect(new_object.fingerprint_algorithm).to eq(payload[:hash][:algorithm])
        end
      end

      context 'without hash parameter in payload' do
        let!(:payload) {{
          name: upload_stub.name,
          content_type: upload_stub.content_type,
          size: upload_stub.size
        }}
        it_behaves_like 'a creatable resource'
      end

      it_behaves_like 'a validated resource' do
        let(:payload) {{
          name: nil,
          content_type: nil,
          size: nil,
          hash: {
            value: nil,
            algorithm: nil
          }
        }}
        it 'should not persist changes' do
          expect(resource).to be_persisted
          expect {
            is_expected.to eq(400)
          }.not_to change{resource_class.count}
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/notexists_projectid/uploads" }
        let(:resource_class) { 'Project' }
      end

      it_behaves_like 'an audited endpoint' do
        let(:expected_status) { 201 }
      end

      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { project }
      end
    end
  end

  describe 'Upload instance' do
    let(:url) { "/api/v1/uploads/#{resource.id}" }

    #View upload details/status
    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/uploads/notexists_resourceid" }
      end
    end
  end

  describe 'Get pre-signed URL to upload a chunk', :vcr do
    let(:resource_class) { Chunk }
    let(:resource_serializer) { ChunkSerializer }
    let!(:resource) { chunk }
    let!(:url) { "/api/v1/uploads/#{upload.id}/chunks" }

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let(:called_action) { "PUT" }
      let!(:payload) {{
        number: chunk_stub.number,
        size: chunk_stub.size,
        hash: {
          value: chunk_stub.fingerprint_value,
          algorithm: chunk_stub.fingerprint_algorithm
        }
      }}
      it_behaves_like 'a creatable resource' do
        let(:expected_response_status) {200}
        let(:new_object) {
          resource_class.where(
            upload_id: upload.id,
            number: payload[:number],
            size: payload[:size],
            fingerprint_value: payload[:hash][:value],
            fingerprint_algorithm: payload[:hash][:algorithm]
          ).last
        }
      end

      it_behaves_like 'a validated resource' do
        let(:payload) {{
          number: nil,
          size: nil,
          hash: {
            value: nil,
            algorithm: nil
          }
        }}
        it 'should not persist changes' do
          expect(resource).to be_persisted
          expect {
            is_expected.to eq(400)
          }.not_to change{resource_class.count}
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/uploads/notexists_resourceid/chunks" }
        let(:resource_class) {"Upload"}
      end

      it_behaves_like 'a storage_provider backed resource'

      it_behaves_like 'an audited endpoint' do
        let(:with_audited_parent) { Upload }
      end
    end
  end

  describe 'Complete the chunked file upload', :vcr do
    let(:url) { "/api/v1/uploads/#{resource.id}/complete" }
    let(:called_action) { "PUT" }
    subject { put(url, nil, headers) }

    before do
      actual_size = 0
      storage_provider.put_container(project.id)
      resource.chunks.each do |chunk|
        object = [resource.id, chunk.number].join('/')
        body = 'this is a chunk'
        storage_provider.put_object(
          project.id,
          object,
          body
        )
        chunk.update_attributes({
          fingerprint_value: Digest::MD5.hexdigest(body),
          size: body.length
        })
        actual_size = body.length + actual_size
      end
      resource.update_attribute(:size, actual_size)
    end

    after do
      resource.chunks.each do |chunk|
        object = [resource.id, chunk.number].join('/')
        storage_provider.delete_object(resource.project.id, object)
      end
    end

    it_behaves_like 'an updatable resource'
    it_behaves_like 'an authenticated resource'
    it_behaves_like 'an authorized resource'

    it_behaves_like 'an identified resource' do
      let(:url) { "/api/v1/uploads/notexists_resourceid/complete" }
    end

    it_behaves_like 'an audited endpoint'

    it_behaves_like 'a storage_provider backed resource' do
      it 'should return an error if the reported size does not match storage_provider computed size' do
        resource.update_attribute(:size, resource.size - 1)
        is_expected.to eq(400)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        response_json = JSON.parse(response.body)
        expect(response_json).to have_key('error')
        expect(response_json['error']).to eq('400')
        expect(response_json).to have_key('reason')
        expect(response_json['reason']).to eq('IntegrityException')
        expect(response_json).to have_key('suggestion')
        expect(response_json['suggestion']).to eq('reported size does not match size computed by StorageProvider')
      end

      it 'should return an error if the reported chunk hash does not match storage_provider computed size' do
        chunk.update_attribute(:fingerprint_value, "NOTTHECOMPUTEDHASH")
        is_expected.to eq(400)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        response_json = JSON.parse(response.body)
        expect(response_json).to have_key('error')
        expect(response_json['error']).to eq('400')
        expect(response_json).to have_key('reason')
        expect(response_json['reason']).to eq('IntegrityException')
        expect(response_json).to have_key('suggestion')
        expect(response_json['suggestion']).to eq('reported chunk hash does not match that computed by StorageProvider')
      end
    end
  end
end
