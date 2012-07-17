require 'active_record'
require 'yaml'

class Image < ActiveRecord::Base
  scope :next_unapproved, lambda{ |count, last_id|
    count ||= 10
    sql = where('approved IS NULL').scoped
    sql = sql.where("id > ?", last_id).scoped unless last_id.blank?
    sql.order('id ASC').limit(count)
  }

  def self.import_from_csv(csv_data, source="de")

# 40567,
# "Landgasthof  Alte Papiermühle"
# "Oberurseler Weg 21"
# "Frankfurt am Main"
# "Germany"
# "069 95770702"
# "http://www.Landgasthof-alte-papiermuehle.de"
# "Eating & Drinking"
# "2246576;2235431;2230613;2230606;1849631;1849626;1849621;1849618;1816999;1816998;1637967;1637962;1637957;1637956;1637953;1637950;1637942;1477445;1477444;1444046"
# "http://www.qype.com/uploads/photos/0224/6576/smiley_bild_1_original.jpg;http://www.qype.com/uploads/photos/0223/5431/valentinstag-0143_original




    row_indeces = {
      :place_id => 0,
      :place_name => 1,
      :place_address => 2,
      :place_city => 3,
      :place_country => 4,
      :place_phone => 5,
      :place_url => 6,
      :place_category => 7,
      :photo_ids => 8,
      :urls => 9,
    }

    csv_parser = FasterCSV.new(csv_data, :encoding => 'u')

    csv_parser.each do |row|
      urls = row[row_indeces[:urls]].split(';')
      photo_ids = row[row_indeces[:photo_ids]].split(';')
      place_id = row[row_indeces[:place_id]]
      urls_with_ids = photo_ids.zip(urls)
      urls_with_ids.each do |id_url_pair|
        create!(
          :photo_id => id_url_pair[0],
          :url => id_url_pair[1],
          :place_id => row[row_indeces[:place_id]],
          :place_name => row[row_indeces[:place_name]],
          :place_address => row[row_indeces[:place_address]],
          :place_city => row[row_indeces[:place_city]],
          :place_country => row[row_indeces[:place_country]],
          :place_phone => row[row_indeces[:place_phone]],
          :place_url => row[row_indeces[:place_url]],
          :place_category => row[row_indeces[:place_url]],
          :source => source
        )
      end
    end

  end


end