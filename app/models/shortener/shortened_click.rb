class Shortener::ShortenedClick < ActiveRecord::Base
  belongs_to :shortened_url
end
