require 'git'

if ARGV.size < 1
  puts "Invoke with the path to the desired target directory."
  exit 1
end

def latest_tag_matching(mod, pattern)
  mod_tags = mod.tags.select { |t| t.name =~ pattern }
  begin
    mod_tags.sort { |a,b|
      mod.gcommit(a).date <=> mod.gcommit(b).date
    }.last
  rescue ArgumentError # sometimes Git::Commit.date bails?! try name.
    mod_tags.sort { |a,b| a.name <=> b.name }.last
  end
end

def export_latest(submodule, target_basedir)
  mod = Git.open(submodule)
  mod_name = File.basename(submodule)
  mod_dir = File.dirname(submodule)
  latest_tag = latest_tag_matching(mod, /^#{mod_name}/)
  latest_tag ||= latest_tag_matching(mod, /^font-#{mod_name}/)
  latest_tag ||= latest_tag_matching(mod, /^XORG-[0-9]/)
  latest_tag ||= latest_tag_matching(mod, /^[0-9.]+/)
  unless latest_tag
    puts "No release tag found for #{submodule}"
    return
  end
  tagname = latest_tag.name
  unless tagname =~ /#{mod_name}/
    tagname = "#{mod_name}-#{tagname}"
  end
  target = File.join(target_basedir, mod_dir, tagname)
  puts "Exporting #{submodule} to #{target}"
  FileUtils.mkpath(target)
  mod.chdir {
    %x[git archive --format=tar #{latest_tag.name} | (cd #{target}; tar xf -)]
  }
end

submodules = Dir.glob("**/.git").map { |gitdir| File.dirname(gitdir) }
submodules.each { |mod| export_latest(mod, ARGV[0]) }
