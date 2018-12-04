class UserFilesController < ApplicationController
  def show
    file_kind = params[:file_kind].to_sym
    data = UserFile.fetch_user_file(params[:user_id], file_kind)
    raise ActionController::MissingFile 'File Not Found' unless data

    send_data(data[:file], type: data[:type])
  end

  def create
    user = User.find_by(id: params[:user_id])
    raise ActionController::BadRequest 'User not found' unless user

    file_kind = params[:file_kind].to_sym
    file_name = params[:file].try(:original_filename)
    file_type = params[:file].try(:content_type)
    file_stream = params[:file].try(:tempfile)
    raise ActionController::BadRequest 'File stream not found' unless file_stream

    UserFile.save_user_file(user.id, file_kind, file_name, file_type, file_stream)
    result = success_result do |data|
      data[:image_src] = "/beltech/#{file_kind}/#{user.id}?rnd=#{Time.now.to_i}" if file_kind == UserFile::KIND_PHOTO
    end
    render json: result
  rescue StandardError => ex
    render json: error_result(ex)
  end

  def destroy
    file_kind = params[:file_kind].to_sym
    user = User.find_by(id: params[:user_id])
    raise ActionController::BadRequest 'User not found' unless user

    UserFile.remove_user_file(user.id, UserFile::KIND_PHOTO)
    result = success_result do |data|
      data[:image_src] = "/plugin_assets/#{Constants::PLUGIN_NAME}/images/avatars/user.png" if file_kind == UserFile::KIND_PHOTO
    end
    render json: result
  rescue StandardError => ex
    render json: error_result(ex)
  end

  private

  def success_result
    result = { result: 'ok' }
    yield result
    result
  end

  def error_result(exception = nil)
    { error_messages: exception ? exception.message : 'Server error' }
  end

  # def user_file_params
  #   params.require(:user_event).permit(:user_id, :issue_id, :event_type, :status, :description, :points, :hours, :start_date, :end_date)
  # end
  #
  # def get_image_extension(assets_path, path)
  #   extension = nil
  #
  #   Constants::ALLOWED_IMAGE_EXTENSIONS.each do |ext|
  #     if File.exist?("#{assets_path}/images/#{path + ext}")
  #       extension = ext
  #       break
  #     end
  #   end
  #
  #   extension
  # end
end
