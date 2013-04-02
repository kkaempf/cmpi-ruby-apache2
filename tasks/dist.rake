task :dist do
  `(cd #{TOPLEVEL}/..; tar -cj --exclude=.git\* --exclude=package --exclude=\*~  --exclude=tmp --exclude-backups -f #{NAME}/package/#{NAME}-#{VERSION}.tar.bz2 #{NAME})`
end
