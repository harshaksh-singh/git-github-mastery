#!/usr/bin/env bash
# Exercise 23.2 (Module 23): which branch names does a ruleset target pattern cover? GitHub
# documents that it uses Ruby's File.fnmatch with File::FNM_PATHNAME, so this script calls
# exactly that function with the Ruby that ships with macOS. No Git involved.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ex3 x23-fnmatch

cat > match.rb <<'RB'
# usage: ruby match.rb PATTERN NAME...
pattern, *names = ARGV
names.each do |name|
  hit = File.fnmatch(pattern, name, File::FNM_PATHNAME)
  puts format("%-16s %-28s %s", pattern, name, hit ? "match" : "-")
end
RB
NAMES='main release/2.4 release/2.4/hotfix-812 releases hotfix-812 hotfix/812 dependabot/uv/main-1f2e'

snip 01-script
run 'cat match.rb'

snip 02-answers
for p in 'release/*' 'release/**/*' 'hotfix*' '*' '**/*' '*/*'; do
  run "/usr/bin/ruby match.rb '$p' $NAMES"
done

lab_end
