#!/usr/bin/env ruby -w

# Original Inspiration: Stephen Benner https://github.com/SteveBenner: https://gist.github.com/SteveBenner/11254428
# Partially Rewritten by Dominyk Tiller https://github.com/DomT4 for Homebrew's cmd use.
# THIS WILL COMPLETELY REMOVE HOMEBREW FROM YOUR SYSTEM

require "fileutils"
require "open3"
require "optparse"

module Homebrew
  def selfdestruct

# Default options
options = {
  :quiet     => false,
  :verbose   => true,
  :dry_run   => false,
  :force     => false,
  :skip_etc  => false,
}

optparser = OptionParser.new do |opts|
  opts.on("-q", "--quiet", "Run script with minimal user-visible output.") do |setting|
    options[:quiet]   = setting
    options[:verbose] = false
  end
  opts.on("-v", "--verbose", "Run script with maximum user-visible output.") { |setting| options[:verbose] = setting }
  opts.on("-d", "--dry-run", "Do not delete anything. Just show what would happen.") do |setting|
    options[:dry_run] = setting
  end
  opts.on("-f", "--force", "Skip the dire warnings and remove everything.") do |setting|
    options[:force] = setting
  end
  opts.on("-skip-etc", "--skip-etc", "Don't remove my `etc` directory.") do |setting|
    options[:skip_etc] = setting
  end
end
optparser.parse!

unless options[:force]
  puts "This will completely, entirely remove Homebrew from your system. Proceed? (Y/N)"
  abort unless gets.rstrip =~ /y|yes/i
end

brew_location = HOMEBREW_PREFIX
cellar_location = HOMEBREW_CELLAR

brewlocal = %W[ LICENSE.txt Library/brew.rb Library/Homebrew Library/Aliases Library/Formula Library/Contributions Library/ENV Library/LinkedKegs ]
$files = []

# Found Homebrew installation
if brew_location
  unless options[:quiet]
    puts "Homebrew found at: #{brew_location}"
    begin # record kegs and taps for later output
      brewed = `brew list`
      tapped = `brew tap`
    rescue StandardError
    end
  end
  # Collect files indexed by git
  begin
    Dir.chdir(brew_location) do
      # Update file list (use popen3 so we can suppress git error output)
      Open3.popen3("git checkout master") { |stdin, stdout, stderr| stderr.close }
      $files += `git ls-files`.split.map {|file| File.expand_path file }
    end
  rescue StandardError => e
    puts e
  end
end

# Collect files
$files += brewlocal.select { |file| File.exist? file }.map {|file| File.expand_path file }
cache = HOMEBREW_CACHE
logs = HOMEBREW_LOGS

abort "Failed to locate any homebrew files!" if $files.empty?

rm =
  if options[:dry_run]
    puts "Deleting #{cache}" unless options[:quiet]
    puts "Deleting #{logs}" unless options[:quiet]
    lambda { |entry| puts "deleting #{entry}" unless options[:quiet] }
  else
    rm_rf cellar_location
    rm_rf HOMEBREW_PREFIX/"etc" unless options[:skip_etc]
    rm_f HOMEBREW_PREFIX/"*.md" # Remove CODEOFCONDUCT, CONTRIBUTING & SUPPORTERS, etc
    rm_rf HOMEBREW_PREFIX/"share/doc/homebrew" # Remove Homebrew documentation

    # Shelling out on `brew prune` enables us to get brew to do the heavy-lifting
    # around removing now-dead symlinks and directories.
    `brew prune`

    # Remove HOMEBREW_CACHE & HOMEBREW_LOGS
    rm_rf cache
    rm_rf logs
    rm_rf HOMEBREW_PREFIX/"opt" # Nothing else should exist here. Safe to remove.

    # files doesn't completely remove these two cleanly, yet.
    rm_rf HOMEBREW_PREFIX/"Library"
    rm_rf HOMEBREW_PREFIX/".git"

    # If this line isn't last, chaos will ensue.
    lambda { |entry| FileUtils.rm_rf(entry, :verbose => options[:verbose]) }
  end

puts "Deleting files..." unless options[:quiet]
$files.each(&rm)

# Print a list of formulae and kegs that were removed as part of the uninstall process
  if brewed
    puts
    puts "The following previously installed formulae were removed:"
    puts brewed
  end

  if tapped
    puts
    puts "The following previously tapped kegs were removed:"
    puts tapped
  end

  puts "Homebrew has been removed from your system. Thanks for brewing with us!"
  puts "You may also wish to revert your $PATH to its original state" unless options[:quiet]
  end # This lines up with def selfdestruct
end

Homebrew::selfdestruct