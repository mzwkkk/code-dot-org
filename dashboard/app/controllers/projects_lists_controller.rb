class ProjectsListsController < ApplicationController
  include LevelsHelper

  def index
    section_id = params[:section_id]
    section_owner_id = Section.find(section_id).user_id
    raise "section can only be accessed by its owner" unless current_user && current_user.id == section_owner_id

    @section_projects = []
    Section.find(section_id).students.each do |student|
      student_storage_id = PEGASUS_DB[:user_storage_ids].where(user_id: student.id).first
      next unless student_storage_id
      PEGASUS_DB[:storage_apps].where(storage_id: student_storage_id[:id], state: 'active').each do |project|
        project_data = get_project_data(student, project)
        @section_projects << project_data if project_data
      end
    end
  end

  private

  # e.g. '/p/applab' -> 'applab'
  def project_type(level)
    level && level.split('/')[2]
  end

  def get_project_data(student, project)
    project_data = project[:value] ? JSON.parse(project[:value]) : {}
    return nil if project_data['hidden'] == true
    {
      channel: project_data['id'],
      name: project_data['name'],
      studentName: student.name,
      type: project_type(project_data['level']),
      updatedAt: project_data['updatedAt'],
    }
  end
end
