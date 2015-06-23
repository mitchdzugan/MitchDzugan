require './lib/nba_helpers'

class NBAObject
	def initialize(base_url, params = {}, use_cache = :yes)
		uri = NbaHelpers.uri_from_base_and_params(base_url, params)
		@_raw_json = NbaHelpers.get_json(uri, use_cache)
	end
end