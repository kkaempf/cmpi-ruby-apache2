require 'rake/clean'
CLEAN.include(
  "**/*~",
  "package/*.bz2",
  "Gemfile.lock",
  "doc"
)
