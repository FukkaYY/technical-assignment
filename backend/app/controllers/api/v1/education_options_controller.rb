module Api
  module V1
    class EducationOptionsController < ApplicationController
      def index
        schools = School.includes(faculties: :departments).order(:school_type, :name)
        render json: {
          data: {
            school_types: School::TYPES.map { |value, label| { value: value, label: label } },
            schools: schools.map { |school| school_json(school) }
          }
        }
      end

      private

      def school_json(school)
        {
          id: school.id,
          name: school.name,
          school_type: school.school_type,
          faculties: school.faculties.sort_by(&:name).map do |faculty|
            {
              id: faculty.id,
              name: faculty.name,
              departments: faculty.departments.sort_by(&:name).map { |department| { id: department.id, name: department.name } }
            }
          end
        }
      end
    end
  end
end
