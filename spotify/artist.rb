module Spotify
  class Artist
    def self.find(ids)
      super(ids, 'artist')
    end

    def self.search(query, limit: 20, offset: 0, market: nil)
      super(query, 'artist', limit: limit, offset: offset, market: market)
    end

    def initialize(options = {})
      @followers  = options['followers']
      @genres     = options['genres']
      @images     = options['images']
      @name       = options['name']
      @popularity = options['popularity']
      @top_tracks = {}

      super(options)
    end

    def albums(limit: 20, offset: 0, **filters)
      url = "artists/#{@id}/albums?limit=#{limit}&offset=#{offset}"
      filters.each do |filter_name, filter_value|
        url << "&#{filter_name}=#{filter_value}"
      end

      response = RSpotify.get(url)
      return response if RSpotify.raw_response
      response['items'].map { |i| Album.new i }
    end

    def related_artists
      return @related_artists unless @related_artists.nil? || RSpotify.raw_response
      response = RSpotify.get("artists/#{@id}/related-artists")

      return response if RSpotify.raw_response
      @related_artists = response['artists'].map { |a| Artist.new a }
    end

    def top_tracks(country)
      return @top_tracks[country] unless @top_tracks[country].nil? || RSpotify.raw_response
      response = RSpotify.get("artists/#{@id}/top-tracks?country=#{country}")

      return response if RSpotify.raw_response
      @top_tracks[country] = response['tracks'].map { |t| Track.new t }
    end
  end
end
