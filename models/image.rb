require 'active_record'

ActiveRecord::Base.establish_connection(
  :database => 'qype_image_tag_development',
  :host => 'localhost',
  :user => 'root',
  :password => '',
  :encoding => 'utf8',
  :adapter => 'mysql'
)

class Image < ActiveRecord::Base
  scope :next_unapproved, lambda{ |count, last_id|
    count ||= 10
    sql = where('approved IS NULL').scoped
    sql = sql.where("id > ?", last_id).scoped unless last_id.blank?
    sql.order('id ASC').limit(count)
  }
end