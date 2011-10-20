require 'uri'

class Domain < ActiveRecord::Base
  belongs_to :realm
  validates_format_of :name, :with => /^[a-z0-9\.\-]+$/
  validates_uniqueness_of :name

  # Provided a block, this method will yield variations on the host with increasing 
  # specificity: 'foo.bar.example.com' will yield "example.com", "bar.example.com",
  # "foo.bar.example.com". For use when resolving realms from domain.
  def self.search_strings_for_url(url, &block)
    segments = url[/(?:http\:\/\/)?([^\/]+)/,1].split('.') # extract the domain and split the subdomains
    candidate = [segments.pop]
    yield(candidate.unshift(segments.pop).join('.')) until segments.empty?
  end
end
