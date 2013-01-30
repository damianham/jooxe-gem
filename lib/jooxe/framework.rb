path = File.expand_path(File.dirname(__FILE__) )

Dir.glob("#{path}/middleware/*.rb") do |f|
  require f
end
    
Dir.glob("#{path}/core/*.rb") do |f|
  require f
end

Dir.glob("#{path}/adapters/*.rb") do |f|
  require f
end

Dir.glob("#{path}/helpers/*.rb") do |f|
  require f
end

Dir.glob("#{path}/support/*.rb") do |f|
  require f
end

Dir.glob("#{path}/*.rb") do |f|
  require f
end

