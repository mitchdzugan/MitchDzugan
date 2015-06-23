require 'json'
require 'open-uri'
require 'uri'
require 'fileutils'

module NbaHelpers
	def NbaHelpers.uri_from_base_and_params(base, params)
		URI(params.reduce(base.downcase) do |uri, item|
			query, param = item.map {|i| i.to_s.downcase}
			pre, post = uri.split(query, 2)
			if (post)
				pre + query + "=" + (param) + 
					((amp_sym_ind = post.index("&")) != nil ? 
						post[amp_sym_ind..-1] : "")
			else
				uri
			end
		end)
	end

	def NbaHelpers.get_json(uri, use_cache = :yes)
		fullpath = File.join(
			File.join("./", uri.path), 
			(0..(uri.query.length/200)).map(&->(i){uri.query.slice(200*i,200)}))
		dir, _ = File.split(fullpath)
		if (File.exists?(fullpath) and use_cache == :yes)
			JSON.parse(open(fullpath).read)
		else
			puts "Not using cache for #{fullpath}"
			text = open(uri).read
			if (!File.exists?(dir))
				FileUtils.mkdir_p(dir)
			end
			File.write(fullpath, text)
			JSON.parse(text)
		end
	end
end
