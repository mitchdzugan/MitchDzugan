require 'json'
require 'open-uri'
require 'uri'
require 'fileutils'
require 'pry'
require 'set'
require 'pp'
require 'nyaplot'
require 'statsample'
require 'futuroscope/convenience'
require 'linefit'
=begin
require 'rubypython'
RubyPython.start


sys = RubyPython.import("sys")

JSON.parse(`python -c 'import sys
import json
print(json.dumps(sys.path))'`).each do |dir|
	if (sys.path.count(dir) == 0)
		sys.path.append(dir)
	end
end
sys.path.append("./scripts")
blog1Py = RubyPython.import("Blog1")
=end

def averageDataSet(xs, ys, ws, xmin, xhigh, divs)
	newYs = (0...divs).map {|i| {sum: 0.0, count: 0.0}}
	width = (xhigh - xmin) / divs
	for i in 0...xs.length
		ind = ((xs[i]-xmin)/width).to_i
		newYs[ind][:sum] += ws[i] * ys[i]
		newYs[ind][:count] += ws[i]
	end
	temp = (0...divs)
		.map {|x| xmin + x*width}
		.zip(newYs.map {|y| if (y[:count] == 0) then -1.0 else y[:sum]/y[:count] end})
		.select {|xys| xys[1] >= 0.0}
	{
		newX: temp.map {|xys| xys[0]},
		newY: temp.map {|xys| xys[1]}
	}
end

def yearStrings(startYear)
	"#{startYear}-#{(y=(startYear+1)%100) < 10 ? "0#{y}" : y.to_s}"
end

def loadNbaJson(url)
	uri = URI(url)
	fullpath = File.join(
		File.join("./", uri.path),
		(0..(uri.query.length/200)).map(&->(i){uri.query.slice(200*i,200)}))
	dir, _ = File.split(fullpath)
	if (File.exists?(fullpath))
		JSON.parse(open(fullpath).read)
	else
		pp url
		text = open(uri).read
		if (!File.exists?(dir))
			FileUtils.mkdir_p(dir)
		end
		File.write(fullpath, text)
		JSON.parse(text)
	end
end

def jsonFromPlayerId(year, pid)
	{
		per100json: loadNbaJson(
			"http://stats.nba.com/stats/playerdashboardbygeneralsplits?DateFrom=" +
			"&DateTo=&GameSegment=&LastNGames=0&LeagueID=00&Location="            +
			"&MeasureType=Base&Month=0&OpponentTeamID=0&Outcome=&PaceAdjust=N"    +
			"&PerMode=Per100Possessions&Period=0&PlayerID=#{pid}&PlusMinus=N"     +
			"&Rank=N&Season=#{yearStrings(year)}"                                 +
			"&SeasonSegment=&SeasonType=Regular+Season&VsConference=&VsDivision="
		)["resultSets"][0]["rowSet"][0],

		advancedJson: loadNbaJson(
			"http://stats.nba.com/stats/playerdashboardbygeneralsplits?DateFrom=" +
			"&DateTo=&GameSegment=&LastNGames=0&LeagueID=00&Location="            +
			"&MeasureType=Advanced&Month=0&OpponentTeamID=0&Outcome=&PaceAdjust=N"+
			"&PerMode=PerGame&Period=0&PlayerID=#{pid}&PlusMinus=N&Rank=N"        +
			"&Season=#{yearStrings(year)}&"                                       +
			"SeasonSegment=&SeasonType=Regular+Season&VsConference=&VsDivision="
		)["resultSets"][0]["rowSet"][0]
	}
end

def statsFromJson(json)
	{
		year: json[:advancedJson][1],
		teamPtsPer100: json[:advancedJson][7].to_f,
		ptsPer100: json[:per100json][26].to_f,
		ts: json[:advancedJson][18].to_f,
		usg: json[:advancedJson][19].to_f,
		mins: json[:advancedJson][2].to_f * json[:advancedJson][6].to_f,
		poss: json[:advancedJson][20].to_f * 48.0 * json[:advancedJson][2].to_f * json[:advancedJson][6].to_f
	}
end

def changeVolEffCoeffs(data, a, b)
	$PlayerToYearToStats.each do |id, years|
		years.each do |year, m|
			m[:volEff] = m[:ts] ** a * m[:ptsPer100] ** b
		end
	end
	data.each do |m|
		m[:sumVolEff] = m[:ids].map do |i|
			$PlayerToYearToStats[i.to_i][yearStrings(m[:years].first)][:volEff]
		end.reduce(0.0, :+)
	end
end

def do1Regression(data, a, b)
	changeVolEffCoeffs(data, a, b)
	lineFit = LineFit.new
	x  = data.map {|d| d[:sumVolEff]}
	y  = data.map {|d| d[:ortg]}
	w  = data.map {|d| d[:mins]}
	lineFit.setData(x, y, w)
	lineFit.rSquared
end
=begin
for i in 200..214
	continuous = 0
	for j in 100001..199999
		yString = "#{i}" + ("#{j}"[1..-1])
		j = loadNbaJson("http://stats.nba.com/stats/playbyplayv2?EndPeriod=10"    +
		"&EndRange=55800&GameID=00#{yString}&RangeType=2&SeasonType=Regular+Season" +
		"&StartPeriod=1&StartRange=0")
		if (j["resultSets"][0]["rowSet"].length == 0)
			continuous = continuous + 1
			if (continuous > 8)
				break
			end
		end
	end
end
=end
$PlayerToYearToStats = Hash.new do |h, k|
	h[k] = Hash.new { |h, k| h[k] =  {}}
end
dataByPlayer = loadNbaJson(
		"http://stats.nba.com/stats/commonallplayers?" +
		"IsOnlyCurrentSeason=0&LeagueID=00&Season=2014-15"
	)["resultSets"][0]["rowSet"]
	.select {|d| d[3].to_i < 2015 and d[4].to_i > 1995}
	.map {|d|
		x = 1
		startingFromYear = d[3].to_i > 1995 ? d[3].to_i : 1996
		{
			playerId: d[0],
			playerName: d[1],
			playerData:
			(startingFromYear..d[4].to_i)
				.map {|y| jsonFromPlayerId(y, d[0])}
				.select {|j| j[:advancedJson] != nil or j[:per100json] != nil}
				.map {|j| statsFromJson(j)}
				.select {|data| data[:teamPtsPer100] * data[:ptsPer100] * data[:ts] != 0}
		}
	}
dataByPlayer.each do |i|
	i[:playerData].each do |j|
		$PlayerToYearToStats[i[:playerId]][j[:year]] = j
	end
end

=begin
data = (2008..2014).map do |y|
		loadNbaJson(
		"http://stats.nba.com/stats/leaguedashlineups?DateFrom=&DateTo=&GameID="  +
		"&GameSegment=&GroupQuantity=5&LastNGames=0&LeagueID=00&Location="        +
		"&MeasureType=Advanced&Month=0&OpponentTeamID=0&Outcome=&PaceAdjust=N"    +
		"&PerMode=PerGame&Period=0&PlusMinus=N&Rank=N&Season=#{yearStrings(y)}"   +
		"&SeasonSegment=&SeasonType=Regular+Season&VsConference=&VsDivision="
		)["resultSets"][0]["rowSet"]
		.map do |rset|
			d = rset[1].split("-").map do |i|
				{
					id: i.to_i,
					year: y,
					usg: $PlayerToYearToStats[i.to_i][yearStrings(y)][:usg],
					ts: $PlayerToYearToStats[i.to_i][yearStrings(y)][:ts],
					pp100: $PlayerToYearToStats[i.to_i][yearStrings(y)][:ptsPer100],
					inPoss: $PlayerToYearToStats[i.to_i][yearStrings(y)][:poss]
				}
			end
			d.each do |m|
				m[:usedPoss] = m[:inPoss] * m[:usg]
				m[:pts] = m[:ts] * m[:usg]
			end

			sumTS = d.reduce(0.0) {|s, m| s + m[:ts]}
			sumUsg = d.reduce(0.0) {|s, m| s + m[:usg]}
			sumPP100 = d.reduce(0.0) {|s, m| s + m[:pp100]}
			{
				ids:  d.map {|m| m[:id]},
				years:  d.map {|m| m[:year]},
				tss:  d.map {|m| m[:ts]},
				usgs:  d.map {|m| m[:usg]},
				pp100s: d.map {|m| m[:pp100]},
				inPosss:  d.map {|m| m[:inPoss]},
				usedPosss:  d.map {|m| m[:usedPoss]},
				ptss: d.map {|m| m[:pts]},
				sumTS: sumTS,
				sumUsg: sumUsg,
				sumPP100: sumPP100,
				mins: rset[9].to_f,
				ortg: 2.0 * rset[21].to_f
			}
		end
	end.reduce(:+)

a = 0.1
aChangesSinceLastImprovement = 0
bestRSquared = {rSquared: 0.0}
while true do
	b = 0.01
	bChangesSinceLastImprovement = 0
	bestRSquared_b = {rSquared: 0.0}
	while true do
		pp [a, b]
		newR = do1Regression(data, a, b)
		if (newR > bestRSquared_b[:rSquared])
			bChangesSinceLastImprovement = 0
			bestRSquared_b[:rSquared] = newR
			bestRSquared_b[:a] = a
			bestRSquared_b[:b] = b
		else
			bChangesSinceLastImprovement += 1
		end
		break if bChangesSinceLastImprovement > 5
		b += 0.01
	end
	if (bestRSquared_b[:rSquared] > bestRSquared[:rSquared])
		aChangesSinceLastImprovement = 0
		bestRSquared[:rSquared] = bestRSquared_b[:rSquared]
		bestRSquared[:a] = bestRSquared_b[:a]
		bestRSquared[:b] = bestRSquared_b[:b]
	else
		aChangesSinceLastImprovement += 1
	end
	break if aChangesSinceLastImprovement > 5
	a += 0.1
end

pp bestRSquared

changeVolEffCoeffs(data, bestRSquared[:a], bestRSquared[:b])

filtData = data.select{|d| d[:mins] > 250}

=begin
puts blog1Py.regressForExponents(
		(0..4).map {|i| filtData.map {|m| m[:ptss][i]}} +
		(0..4).map {|i| filtData.map {|m| m[:usedPosss][i]}} +
		(0..4).map {|i| filtData.map {|m| m[:inPosss][i]}},
		filtData.map {|m| m[:ortg]}
	)

dMin = -0.15
dMax =  0.15
sep = (dMax - dMin) / 10.0
cur = dMin
a = []
loop do
	break if (cur > dMax)
	prev = cur
	cur += sep
	a << [prev,cur]
end

pData = a.map do |low, high|
	dataChunk = data.select {|d| d[:totalUsg] >= low and d[:totalUsg] < high}
	v = dataChunk.reduce(0) {|s, d| s + d[:diffOrtg] * d[:minutes]} /
		dataChunk.reduce(0) {|s, d| s + d[:minutes]}
	[(low + high) / 2.0, v]
end


x = data.map {|d| d[:totalUsg]}
y = data.map {|d| d[:diffOrtg]}
w = data.map {|d| d[:minutes]}

plot = Nyaplot::Plot.new
df = Nyaplot::DataFrame.new({
	x: data.select {|d| d[:minutes] > 450}.map {|d| d[:totalUsg]},
	y: data.select {|d| d[:minutes] > 450}.map {|d| d[:diffOrtg]}
})
plot.add_with_df(df, :scatter, :x, :y)
plot.export_html("./plots/totalUsgVsDiffTs.html")

lineFit = LineFit.new
lineFit.setData(x, y, w)
pp lineFit.coefficients
pp lineFit.rSquared
=end

flatData = dataByPlayer.map {|player| player[:playerData].map {
		|playerYear| playerYear.merge({
			playerId: player[:playerId], playerName: player[:playerName]
		})
	}}.reduce(:+)
	.map {|playerYear|
		playerYear[:volEff] = 200.0 * playerYear[:ts] * playerYear[:usg]
		playerYear[:restOfTeamEff] = (playerYear[:teamPtsPer100] - (200.0 * playerYear[:usg] * playerYear[:ts])) / (1.0 - playerYear[:usg])
		playerYear[:oeff] = playerYear[:ptsPer100] + ((1.0 - playerYear[:usg]) * (101.182 + (5.787 * playerYear[:usg])))
		playerYear[:teamY] = (playerYear[:teamPtsPer100] - playerYear[:ptsPer100]) / (1.0 - playerYear[:usg])
		playerYear
	}

filtData = flatData.select{|d| d[:mins] > 500}

=begin
lnTeamPtsPer100,lnPtsPer100,lnTs,lnUsg =
	[:teamPtsPer100, :ptsPer100, :ts, :usg].map do |sym|
		filtData.map {|d| d[sym]}
	end

ds = {
	'ts' => lnTs.to_scale,
	'usg' => lnUsg.to_scale,
	'ptsPer100' => lnPtsPer100.to_scale,
	'teamPtsPer100' =>  lnTeamPtsPer100.to_scale
}.to_dataset
lr = Statsample::Regression.multiple(ds,'teamPtsPer100')
puts lr
tsExp = lr.coeffs["ts"]
usgExp = lr.coeffs["usg"]
ptsPer100Exp = lr.coeffs["ptsPer100"]

p "PtsPer100Exp: #{ptsPer100Exp} -|- tsExp: #{tsExp} -|- usgExp: #{usgExp}"

lnOrtg,lnSumTs,lnSumPP100 =
	[:ortg, :sumTS, :sumPP100].map do |sym|
		filtData.map {|d| d[sym]}
	end

ds = {
	'SumPP100' => lnSumPP100.to_scale,
	'SumTs' => lnSumTs.to_scale,
	'Ortg' =>  lnOrtg.to_scale
}.to_dataset
lr = Statsample::Regression.multiple(ds,'Ortg')
puts lr
tsExp = lr.coeffs["SumTs"]
ptsPer100Exp = lr.coeffs["SumPP100"]

p "PtsPer100Exp: #{ptsPer100Exp} -|- tsExp: #{tsExp}"













=end
=begin
=end
=begin
newData = averageDataSet(
		filtData.map {|d| d[:usg]},
		filtData.map {|d| d[:restOfTeamEff]},
		filtData.map {|d| d[:mins]},
		0.00, 0.4, 40
	)

pp newData
x = newData[:newX]
y = newData[:newY]
plot = Nyaplot::Plot.new
df = Nyaplot::DataFrame.new({
	x: x,
	y: y
})
plot.add_with_df(df, :scatter, :x, :y)
plot.export_html("./plots2/other.html")

ds = {
	'x' => x.to_scale,
	'y' => y.to_scale
}.to_dataset
lr=Statsample::Regression.multiple(ds,'y')
puts lr.summary
=begin
=end
#pp filtData
[
	["PointsPer100", :ptsPer100],
	["Usage", :usg],
	["TrueShooting", :ts],
	["VolumeEfficiency", :oeff]
].each do |str, sym|
	x  = filtData.map {|d| d[sym]}
	y  = filtData.map {|d| d[:teamPtsPer100]}
	xg = filtData.map {|d| d[sym]}
	yg = filtData.map {|d| d[:teamPtsPer100]}
	plot = Nyaplot::Plot.new
	df = Nyaplot::DataFrame.new({
		x: xg,
		y: yg
	})
	plot.add_with_df(df, :scatter, :x, :y)
	plot.export_html("./plots2/" + str + ".html")

	ds = {
		str => x.to_scale,
		'y' => y.to_scale
	}.to_dataset
	lr=Statsample::Regression.multiple(ds,'y')
	puts lr.summary
end

=begin
str = "VolumeEfficiencyWithExps.html"
x = filtData.map {|d| Math.tan((d[:ts] - 0.220) * Math::PI / 2.5) * d[:usg] } # * d[:usg] ** usgExp}
y = filtData.map {|d| d[:teamPtsPer100]}
plot = Nyaplot::Plot.new
df = Nyaplot::DataFrame.new({
	x: x,
	y: y
})
plot.add_with_df(df, :scatter, :x, :y)
plot.export_html(str)

ds = {
	str => x.to_scale,
	'y' => y.to_scale
}.to_dataset
lr=Statsample::Regression.multiple(ds,'y')
puts lr.summary
=end
=begin

dataByPlayer.each do |i|
	i[:playerData].each do |j|
		j[:volEff] = $PlayerToYearToStats[i[:playerId]][j[:year]][:volEff]
	end
end


playerVolEffs = dataByPlayer.map do |player|
	player[:volEffs] = player[:playerData].map do |playerYear|
		{
			year: playerYear[:year],
			ts: playerYear[:ts],
			usg: playerYear[:usg],
			mins: playerYear[:mins],
			oeff: playerYear[:oeff]
		}
	end
	player
end
=end

puts("Best Single Seasons")
puts(flatData
	.select {|playerYear| playerYear[:mins] > 1250}
	.sort {|a, b| b[:oeff] <=> a[:oeff]}
	.take(10)
)

# pp dataByPlayer
=begin
puts("Largest Single Year Improvement From Career High")
puts(playerVolEffs.map do |player|
	player[:volEffs]
		.select {|playerYear| playerYear[:mins] > 1250}
		.reduce ({
				biggestJump: 0, careerHigh: nil,
				careerHighSet: false, arr: []
			}) do |acc, cur|
				acc[:arr] = acc[:arr].push(cur)
				if (!acc[:careerHighSet])
					acc[:careerHighSet] = true
					acc[:careerHigh] = cur[:volEff]
				end
				diff = cur[:volEff] - acc[:careerHigh]
				if (diff > 0)
					if (diff > acc[:biggestJump])
						acc[:biggestJump] = diff
					end
					acc[:careerHigh] = cur[:volEff]
				end
				acc
			end
		.merge({:playerId => player[:playerId], :playerName => player[:playerName]})
	end
	.select {|player| player[:careerHighSet]}
	.sort {|a, b| b[:biggestJump] <=> a[:biggestJump]}
	.map {|d| {
			id: d[:PlayerID], name: d[:playerName], imp: d[:biggestJump]
		}}
	.take(10)
)
=end
