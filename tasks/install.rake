task :install do
  `mkdir -p #{DESTDIR}#{MOFDIR}`
  `install -m 0644 mof/*.mof #{DESTDIR}#{MOFDIR}`
  `install -m 0644 registration/*.reg #{DESTDIR}#{MOFDIR}`
  `mkdir -p #{DESTDIR}#{CMPIDIR}`
  `install -m 0644 src/*.rb #{DESTDIR}#{CMPIDIR}`
end
