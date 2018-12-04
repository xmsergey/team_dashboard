class UserFile < ActiveRecord::Base
  KIND_PHOTO = :photo
  unloadable

  belongs_to :user

  serialize :files

  def self.fetch_user_file(user_id, file_kind)
    user_file = UserFile.where(user_id: user_id).first
    result = nil
    if user_file && user_file.files[file_kind]
      result = {}.merge(user_file.files[file_kind])
      result[:file] = user_file.send(file_kind)
    end
    result
  end

  def self.remove_user_file(user_id, file_kind)
    user_file = UserFile.where(user_id: user_id).first
    if user_file && user_file.files[file_kind]
      user_file.send("#{file_kind}=", nil)
      user_file.remove_file_description(file_kind)
      user_file.save!
    end
  end

  def self.save_user_file(user_id, file_kind, file_name, content_type, file_stream)
    user_file = UserFile.find_or_initialize_by(user_id: user_id)
    file_size = nil
    begin
      user_file.send("#{file_kind}=", file_stream.read)
      file_stream.close
      file_size = user_file.send("#{file_kind}").try(:length)
    rescue StandardError => ex
      raise "Error saving photo from stream: #{ex.message}"
    end
    user_file.add_file_description(file_kind, file_name, content_type, file_size)
    user_file.save!
    user_file
  end

  def add_file_description(file_kind, file_name, content_type, length)
    description = self.files || {}
    description[file_kind] = { name: file_name, type: content_type, length: length }
    self.files = description
  end

  def remove_file_description(file_kind)
    description = self.files || {}
    if description.has_key?(file_kind)
      description.delete(file_kind)
      self.files = description
    end
  end
end
