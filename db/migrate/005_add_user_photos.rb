class AddUserPhotos < ActiveRecord::Migration
  def change
    Dir[get_dir_path].each do |image_file|
      user = find_user(image_file)
      next unless user

      UserFile.save_user_file(user.id, UserFile::KIND_PHOTO,
        File.basename(image_file), 'image/JPG', File.new(image_file))
    end
  end

  def find_user(image_file)
    name = File.basename(image_file, '.*')
    user = nil
    if name.include?('_')
      names = name.split('_')
      user = User.where(lastname: names.last, firstname: names.first).first
    end
    user
  end

  def get_dir_path
    File.join(Redmine::Plugin.find(TeamDashboardConstants::PLUGIN_NAME).assets_directory, 'images/avatars/*.jpg')
  end
end
