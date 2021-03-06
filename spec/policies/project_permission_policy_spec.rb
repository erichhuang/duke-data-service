require 'rails_helper'

describe ProjectPermissionPolicy do
  let(:permission) { FactoryGirl.create(:project_permission) }
  let(:user) { permission.user }
  let(:project_permission) { FactoryGirl.build(:project_permission, project: permission.project) }
  let(:other_project_permission) { FactoryGirl.create(:project_permission) }
  
  let(:scope) { subject.new(user, project_permission).scope }

  subject { described_class }

  permissions ".scope" do
    it 'returns project_permissions for projects with project permissions' do
      expect(project_permission.save).to be_truthy
      expect(permission).to be_persisted
      expect(other_project_permission).to be_persisted
      expect(scope.all).to include(permission)
      expect(scope.all).to include(project_permission)
      expect(scope.all).not_to include(other_project_permission)
    end
  end

  permissions :show? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_project_permission)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, project_permission)
    end
  end

  permissions :create? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_project_permission)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, project_permission)
    end
  end

  permissions :update? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_project_permission)
    end

    it 'denies access to project permission for current_user' do
      is_expected.not_to permit(user, permission)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, project_permission)
    end
  end

  permissions :destroy? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_project_permission)
    end

    it 'denies access to project permission for current_user' do
      is_expected.not_to permit(user, permission)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, project_permission)
    end
  end
end
