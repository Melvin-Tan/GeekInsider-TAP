class ApiController < ApplicationController
  before_action :parse_request, only: [:register, :suspend, :retrievefornotifications]

  def register
    validate_json({teacher: String, students: Array})
    return if performed?

    teacher = find_or_create_teacher(@json['teacher'])
    return if performed?

    # Register each student to teacher
    @json['students'].each do |student_email|
      student = find_or_create_student(student_email)
      return if performed?
      find_or_create_registration(student, teacher)
      return if performed?
    end
  end

  def common_students
    # Workaround: params['teacher'] will only return 1 teacher 
    #             instead of the list of teachers,
    #             due to them sharing the same key.
    #             Thus, we roll our own parser for this
    emails = get_emails_from_query_string(request.query_string)
    return if performed?

    if emails.empty?
      render json: {students: []}
      return
    end

    # Find all the students that belongs to all given teachers
    students = find_students(emails.first)
    return if not students.present?
    emails.drop(1).each do |email|
      extra_students = find_students(email)
      return if not extra_students.present?
      students &= extra_students
    end

    render json: {students: students.map {|student| student.email}}
  end

  def suspend
    validate_json({student: String})
    return if performed?

    student = Student.find_by_email(@json['student'])
    if student.nil?
      render_error "Student email not found: #{@json['student']}"
      return
    end

    student.update_attributes!(is_suspended: true)
  end

  def retrievefornotifications
    validate_json({teacher: String, notification: String})
    return if performed?

    teacher = Teacher.find_by_email(@json['teacher'])
    if teacher.nil?
      render_error "Teacher email not found: #{@json['teacher']}"
      return
    end

    # receipient is the union of teacher's students and mentioned students that are not suspended
    teacher_students = find_students(teacher.email)
    mentioned_students = get_mentioned_students(@json['notification'])
    recipients = (teacher_students | mentioned_students) \
                   .select {|student| not student.is_suspended} \
                   .map {|student| student.email}
    render json: {recipients: recipients}
  end

  def error
    render_error 'No such API endpoint'
  end

  private
    def render_error(message)
      render json: {message: message}, status: :bad_request
    end

    def parse_request
      @json = JSON.parse(request.body.read)
    end

    def validate_json(required_keys)
      # Keys and key types must be the same. The length must match too.
      unless (@json.length == required_keys.length) \
             and required_keys.all? {|key, key_type| @json.has_key?(key.to_s) and @json[key.to_s].class == key_type}
        render_error "Exactly #{required_keys.length} keys #{required_keys.to_s.gsub(':', '')} must be provided."
      end
    end

    def find_or_create_entry(model, attributes, error_message)
      entry = model.find_by(attributes)
      if entry.nil?
        entry = model.new(attributes)
        unless entry.save
          render_error error_message
          return
        end
      end
      entry
    end

    def find_or_create_teacher(email)
      find_or_create_entry(Teacher, 
                           {email: email}, 
                           "Teacher email format is invalid: #{email}")
    end

    def find_or_create_student(email)
      find_or_create_entry(Student, 
                           {email: email}, 
                           "Student email format is invalid: #{email}")
    end
  
    def find_or_create_registration(student, teacher)
      find_or_create_entry(Registration, 
                           {student_id: student.id, teacher_id: teacher.id}, 
                           "Failed to register student #{student.email} to teacher #{teacher.email}")
    end

    def get_emails_from_query_string(query_string)
      params = URI.decode(query_string).split('&')
      unless params.all? {|param| param.start_with? 'teacher='}
        render_error "All parameter headings must be 'teacher'"
        return
      end 
      params.map {|teacher| teacher.gsub('teacher=', '')}
    end

    def find_students(teacher_email)
      teacher = Teacher.find_by_email(teacher_email)
      if teacher.nil?
        render_error "Teacher email not found: #{teacher_email}"
        return
      end
      teacher.students
    end

    def get_mentioned_students(notification)
      notification \
        .split(' ') \
        .select {|word| word.start_with?('@')} \
        .map {|mention| Student.find_by_email(mention[1..-1])} \
        .select {|student| student.present?}
    end
end