class MembershipSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id, :project, :user, :project_roles

  def project
    object.project_id
  end

  def user
    {
      id: object.user.uuid,
      full_name: object.user.display_name,
      email: object.user.email
    }
  end

  def project_roles
    Array.new
  end
end
