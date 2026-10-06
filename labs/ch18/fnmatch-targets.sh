#!/usr/bin/env bash
# How a ruleset target pattern matches branch names. GitHub documents that it uses Ruby's
# File.fnmatch with the File::FNM_PATHNAME flag, so this demo calls exactly that function
# with the Ruby that ships with macOS (/usr/bin/ruby). No Git involved. Chapter 18, section 18.3.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch18 fnmatch-targets

cat > match.rb <<'RB'
# usage: ruby match.rb PATTERN NAME...
pattern, *names = ARGV
names.each do |name|
  hit = File.fnmatch(pattern, name, File::FNM_PATHNAME)
  puts format("%-14s %-22s %s", pattern, name, hit ? "match" : "-")
end
RB

snip 01-script
run 'cat match.rb'

snip 02-star-stops-at-slash
run '/usr/bin/ruby match.rb "qa/*" qa/login qa/login/retry qa'
run '/usr/bin/ruby match.rb "qa/**/*" qa/login qa/login/retry qa/a/b/c'

snip 03-common-targets
run '/usr/bin/ruby match.rb "release/*" release/1.0 release/1.0/hotfix releases/1.0'
run '/usr/bin/ruby match.rb "*feature*" feature-x my-feature feature/x team/feature/x'
run '/usr/bin/ruby match.rb "**/*" main feature/x a/b/c'
run '/usr/bin/ruby match.rb "*" main feature/x'

snip 04-tags
run '/usr/bin/ruby match.rb "v*" v1.0.0 v2 version-notes release/v1'
run '/usr/bin/ruby match.rb "v[0-9]*" v1.0.0 version-notes'

lab_end
