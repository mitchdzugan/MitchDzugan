require './lib/nba_object'

class CommonPlayer
	attr_accessor :playerId, :playerName, :activeThisYear, 
				  :startYear, :endYear, :playerStringCode
	def initialize(l)
		@playerId, @playerName, @activeThisYear,
		@startYear, @endYear, @playerStringCode = l
	end
end

class CommonAllPlayers < NBAObject
	attr_accessor :players

	def initialize(*params)
		base_url = 
			"http://stats.nba.com/stats/commonallplayers?" +
			"IsOnlyCurrentSeason=0&LeagueID=00&Season=2014-15"
		super(base_url, *params)
		@players = @_raw_json["resultSets"][0]["rowSet"].map {|l| CommonPlayer.new(l)}
	end
end