#!/usr/bin/env ruby

require 'open-uri'
require 'json'
require 'uri'

$conf = {
        :wifi    => {:repo => 'mirobot/mirobot-wifi', :file => 'mirobot-v2-wifi'},
        :ui      => {:repo => 'mirobot/mirobot-wifi', :file => 'mirobot-v2-ui'},
        :arduino => {:repo => 'mirobot/mirobot-arduino', :file => 'mirobot-v2-firmware'}
       }

def getLatest(type, prerelease)
  out = {:assets => [], :type => type, :prerelease => prerelease}
  res = JSON.parse(open("https://api.github.com/repos/#{$conf[type][:repo]}/releases") { |f| f.read })
  res.each do |rel|
    if prerelease == rel['prerelease']
      if rel['assets'].length > 0
        rel['assets'].each do |asset|
          if asset['name'].start_with?($conf[type][:file])
            out[:version] = rel['tag_name'].gsub('v', '')
            out[:assets] << asset['browser_download_url']
          end
        end
        return out unless out[:assets].empty?
      end
    end
  end
  out
end

def downloadAsset(asset)
  outfile = "site/mirobot-v2/assets/#{File.basename(URI.parse(asset).path)}"
  unless File.exist?(outfile)
    puts "Downloading #{asset}"
    content = open(asset) { |f| f.read }
    File.open(outfile, 'wb') { |f| f.write(content) }
  end
  outfile
end

out = {:latest => {}, :prerelease => {}}
assets = []
[false, true].each do |prerelease|
  $conf.keys.each do |type|
    latest = getLatest(type, prerelease)
    next unless latest[:version]
    out[prerelease ? :prerelease : :latest][type] = {:version => latest[:version]}
    out[prerelease ? :prerelease : :latest][type][:assets] = latest[:assets].map do |asset|
      a = downloadAsset(asset)
      assets << a
      a.gsub('site', '')
    end
  end
end

# Write the index to file
File.open('site/mirobot-v2/versions.json', 'w') { |f| f.write(JSON.generate(out)) }

# Clean up assets
Dir.glob('site/mirobot-v2/assets/*').each do |f|
  File.delete(f) unless assets.include?(f)
end
