# Simple craigslist RSS poller.
#
# Keep this running if you want your mac to tell you when there are new
# listings for your RSS feed
#
# To execute:
#
# export CLW_RSS="http://my_cl_rss_feed"; ruby lib/craigslist_watcher.rb
#
#
#
# Requirements:
#   ruby 1.9.3
#   Mac OSX
#
# Author: David Colebatch <dc@xnlogic.com>
#

require 'rss'
require 'open-uri'

# Example RSS feed:
CLW_RSS = ENV['CLW_RSS'] || "http://toronto.en.craigslist.ca/search/sss?query=11%20macbook%20air&srchType=A&format=rss"

class CraigslistWatcher
  attr_accessor :rss_feed_url, :feed_title, :items

  # Handy when you're hacking in IRB
  def self.reload!
    load __FILE__
  end

  def initialize
    self.rss_feed_url = CLW_RSS
    self.items = {}
  end

  # Run the RSS checking loop!
  def run!
    while true
      begin
        listings = fetch_listings
      rescue
        puts "Exception while fetching listings: #{e}"
      end
      if listings
        new_listings = process_listings( listings )
        if new_listings.any?
          puts "======================================"
          puts "  #{new_listings.count} new listings!"
          puts "  (feed: #{feed_title})"
          puts "======================================"

          `say "#{new_listings.count} new listings!"`
          alert new_listings
        end
      else
        puts "no listings at '#{ rss_feed_url }'"
      end
      sleep 300
    end
    true
  end

  def fetch_listings
    open(rss_feed_url) do |rss|
      begin
        feed = RSS::Parser.parse(rss)
        if feed
          self.feed_title = feed.channel.title || 'Unknown feed title'
          feed.items
        end
      rescue RSS::MissingTagError => e
        puts "I assume no results were found (#{e.message})"
      end
    end
  end

  def process_listings(listings)
    listings.select do |item|
      process_item item
    end
  end

  def process_item(item)
    unless items.key? item.link
      items[item.link] = item
    end
  end

  def alert(new_listings)
    new_listings.sort_by { |item|  item.date.to_i }.each do |item|
      puts "Item: #{item.title}"
      puts "Date: #{item.date}"
      puts "Link: #{item.link}"
      puts "Description: #{item.description}"
      puts "----------------------------------------------"
    end
  end
end

cw = CraigslistWatcher.new
cw.run!

