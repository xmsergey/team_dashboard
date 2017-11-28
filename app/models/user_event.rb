class UserEvent < ActiveRecord::Base
  unloadable

  belongs_to :user
  belongs_to :issue

  default_scope { order('user_events.created_at desc') }

  validates_presence_of :user_id, :event_type

  validate :validate_type

  scope :next_day_event, -> do
    prev_business_day_date = LibraryFunctions.next_business_day(User.current.today)
    where("(start_date <= ? and end_date >= ?) or (start_date = ? and end_date is null)", prev_business_day_date, prev_business_day_date, prev_business_day_date)
  end

  scope :for_date, ->(date) do
    where("(start_date <= ? and end_date >= ?) or (start_date = ? and end_date is null)", date, date, date)
  end

  scope :timesheet_affected, -> { where() }
  scope :shared_tasks, -> { where(event_type: SHARED_TASK) }
  scope :current_shared_tasks, -> { shared_tasks.where('(start_date is null or start_date <= DATE(DATE_SUB(UTC_TIMESTAMP(), INTERVAL -1 DAY))) and (end_date is null or end_date >= DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 17 HOUR)))') }
  scope :photo_affected_events, -> { where(event_type: [VACATION, DAY_OFF, OUT_OF_ORDER, LEAVE_OF_ABSENCE]) }
  scope :current_photo_affected_event, -> { next_day_event.photo_affected_events }
  scope :unavailable, -> { photo_affected_events }
  scope :today, -> { for_date(User.current.today) }
  scope :tomorrow, -> { next_day_event }

  OVERLAY_IMAGES_BASIC_PATH = 'user_statuses'

  VACATION = 'vacation'.freeze
  DAY_OFF = 'day_off'.freeze
  OUT_OF_ORDER = 'out_of_order'.freeze
  FAILURE = 'failure'.freeze
  OVERTIME = 'overtime'.freeze
  SHARED_TASK = 'shared_task'.freeze
  PM_TIMESHEET_OK = 'pm_timesheet_ok'.freeze
  LEAVE_OF_ABSENCE = 'leave_of_absence'.freeze

  EVENT_TYPES = [
      SHARED_TASK,
      VACATION,
      DAY_OFF,
      OUT_OF_ORDER,
      FAILURE,
      OVERTIME,
      PM_TIMESHEET_OK,
      LEAVE_OF_ABSENCE
  ].freeze

  EVENT_HUMAN_READABLE = {
      VACATION => 'Vacation',
      DAY_OFF => 'Day off',
      OUT_OF_ORDER => 'Was sick',
      FAILURE => '****** up',
      OVERTIME => 'Overtime',
      SHARED_TASK => 'Shared task',
      PM_TIMESHEET_OK => 'PM Timesheet OK',
      LEAVE_OF_ABSENCE => 'Leave of absence'
  }.freeze

  EVENT_TYPES.each do |event_type|
    define_method("#{event_type}?") { check_event_type(event_type) }
  end

  class << self
    def valid_type?(type)
       EVENT_TYPES.include?(type)
    end

    def event_types_array_for_select
      EVENT_TYPES.map do |event_type|
        caption = event_type.split('_').map { |et| et.capitalize }.join(' ')
        [caption, event_type]
      end
    end
  end

  def check_event_type(type)
    self.event_type.eql?(type)
  end

  def validate_type
    errors.add(:base, 'The type is invalid.') unless self.valid_type?
  end

  def valid_type?
    UserEvent.valid_type?(self.event_type)
  end

  def overlay_image_src
    "#{OVERLAY_IMAGES_BASIC_PATH}/#{self.event_type}.png"
  end

  def event_range
    ret_val = self.start_date.strftime('%m/%d/%Y')
    ret_val << " - #{self.end_date.strftime('%m/%d/%Y')}"if self.end_date
    # No return value. It is expected - no range in case of blank end_date
  end

  def to_s
    EVENT_HUMAN_READABLE[self.event_type]
  end
end
