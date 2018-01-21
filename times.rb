require 'protobuf'
require 'google/transit/gtfs-realtime.pb'
require 'net/http'
require 'uri'
require 'pry'

class FeedUrls
  def nqrw
    build_url("16")
  end

  def bdfm
    build_url("21")
  end

  def ace
    build_url("26")
  end

  def build_url(feed_id)
    "http://datamine.mta.info/mta_esi.php?key=#{token}&feed_id=#{feed_id}"
  end

  def token
    ENV.fetch 'MTA_TOKEN'
  end
end

TrainTime = Struct.new(:route_id, :stop_id, :arrival_time_seconds) do
  def train
    route_id
  end

  def stop
    stop_id[0...-1]
  end

  def direction
    stop_id[-1]
  end

  def arrival_at
    Time.at(arrival_time_seconds)
  end

  def to_s
    "#{train} arriving at #{arrival_at.strftime('%H:%M')} going #{direction}"
  end
end

class TrainTimes
  attr_reader :feed_url

  def initialize(feed_url)
    @feed_url = feed_url
  end

  def times
    @times ||= parsed_feed_data
      .entity
      .map(&:trip_update)
      .compact
      .flat_map { |e|
        e.stop_time_update.map { |u|
          TrainTime.new(e.trip.route_id, u.stop_id, u.arrival.time)
        }
      }
  end

  def parsed_feed_data
    @parsed_feed_data ||= Transit_realtime::FeedMessage.decode(raw_feed_data)
  end

  def raw_feed_data
    @raw_feed_data ||= Net::HTTP.get(URI.parse(feed_url))
  end
end


urls = FeedUrls.new
nqrw = TrainTimes.new(urls.nqrw)
bdfm = TrainTimes.new(urls.bdfm)
ace = TrainTimes.new(urls.ace)

all_times = [
  nqrw.times.select { |e| e.stop == "G19" },
  bdfm.times.select { |e| e.stop == "G19" },
  ace.times.select { |e| e.stop == "G19" },
].flatten

directional_groups = all_times.group_by { |t| t.direction }
directional_groups.each do |(direction, trains)|
  puts "#{direction}"
  trains.sort_by(&:arrival_time_seconds).take(4).each do |t|
    puts "\t#{t}"
  end
end
