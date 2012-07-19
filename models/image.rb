require 'active_record'
require 'yaml'
require 'fastercsv'

class Image < ActiveRecord::Base

def self.next_unapproved(count, ids, threshold_count)
  images = []
  id_clause = "and id not in (#{ids})" unless ids.blank?
  sources_lower_than(threshold_count).each do |source|
    break if images.size >= count.to_i
    images << self.find_by_sql("select * from images where approved is null and source = '#{source}' and place_id not in (select distinct place_id from images where approved = true) #{id_clause} group by place_id order by id limit #{count};")
  end
  images.flatten[0..(count.to_i-1)]
end

  def self.images_left(exclude_threshold)
    sources_to_exclude = Image.exclude_sources_higher_than(exclude_threshold)
    if sources_to_exclude.empty?
      Image.where('approved IS NULL').count
    else
      Image.where('approved IS NULL AND source NOT IN (?)', sources_to_exclude).count
    end
  end

  def self.not_satisfied_sources(below_)
    
    result = self.connection.execute(<<-EOS
      select source, count(distinct place_id) as places
      from images
      group by source
      having places < 200
    EOS
    )
    counts = {}
    result.each do |row|
      counts[row[0]] = row[1]
    end
    counts
  end

  def self.approved_source_counts
    result = self.connection.execute(<<-EOS
      SELECT source, count(distinct place_id)
      FROM images
      WHERE approved = true
      GROUP BY source
    EOS
    )
    counts = {}
    result.each do |row|
      counts[row[0]] = row[1]
    end
    counts
  end

  def self.unapproved_source_counts
    result = self.connection.execute(<<-EOS
      SELECT source, count(distinct place_id)
      FROM images
      WHERE approved IS NULL
      GROUP BY source
    EOS
    )
    counts = {}
    result.each do |row|
      counts[row[0]] = row[1]
    end
    counts
  end

  def self.exclude_sources_higher_than(source_count_threshold)
    sources_to_exclude = []
    approved_source_counts.each_pair do |source, count|
      sources_to_exclude << source if count.to_i > source_count_threshold.to_i
    end
    sources_to_exclude
  end


  def self.sources_lower_than(source_count_threshold)
    result = self.connection.execute(<<-EOS
      select source, count(distinct place_id) as places
      from images
      group by source
      having places < #{source_count_threshold.to_i}
    EOS
    )
    sources = []
    result.each do |row|
      sources << row[0]
    end
    sources.flatten
  end

  def self.import_from_csv(csv_data,file_name,source)

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
      urls = row[row_indeces[:urls]].to_a.split(';')
      photo_ids = row[row_indeces[:photo_ids]].to_a.split(';')
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
          :place_category => row[row_indeces[:place_category]],
          :source => source,
          :import => file_name
        )
      end
    end

  end


end