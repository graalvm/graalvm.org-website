#!/bin/bash
set -ex
export JEKYLL_ENV=production

# Build the libraries and frameworks page from the latest metadata
if [[ -e _graalvm-reachability-metadata ]]; then
  echo "_graalvm-reachability-metadata already exists; remove it before building." >&2
  exit 1
fi
trap 'rm -rf _graalvm-reachability-metadata' EXIT
git clone --depth 1 https://github.com/oracle/graalvm-reachability-metadata.git _graalvm-reachability-metadata
ruby _scripts/generate-library-and-framework-list.rb

cp pages/native-image/libraries-and-frameworks-with-header.md pages/native-image/libraries-and-frameworks.md

# Build the latest documentation
# Build the non-versioned site and redirects for non-versioned URLs
./_scripts/pull-extra.sh release/graal-vm/25.5
ruby _scripts/process_front_matter.rb --add-title pages release-notes
ruby _scripts/process_front_matter.rb --add-title --add-version-to-permalinks --add-versioned-redirects docs truffle/docs espresso/docs web-image/docs pages/redirects
bundle exec jekyll build --config _configs/config_community_latest.yml

# Build the versioned feature release documentation
bundle exec jekyll build --destination jdk25.5 --config _configs/config_community_jdk25i.yml
./_scripts/merge_sitemaps.rb _site/sitemap.xml jdk25.5/sitemap.xml https://www.graalvm.org/jdk25.5/
rsync -av jdk25.5/jdk25.5 _site/
rsync -av --exclude "*.html" jdk25.5/docs _site/
rm -rf jdk25.5

# Build DEV documentation (always from master)
./_scripts/pull-extra.sh master
ruby _scripts/process_front_matter.rb --add-title --add-version-to-permalinks docs truffle/docs espresso/docs web-image/docs pages/redirects
bundle exec jekyll build --destination dev --config _configs/config_community_dev.yml
./_scripts/merge_sitemaps.rb _site/sitemap.xml dev/sitemap.xml https://www.graalvm.org/dev/
rsync -av dev/dev _site/
rsync -av --exclude "*.html" dev/docs _site/
rm -rf dev

# Restore source pages that process_front_matter.rb mutates while generating versioned redirects and canonical URLs
git checkout -- \
  pages/redirects/fastr.md \
  pages/redirects/graaljs.md \
  pages/redirects/graalpy.md \
  pages/redirects/graalwasm.md \
  pages/redirects/truffleruby.md \
  pages/ruby/ruby.md

echo "Website build completed successfully: _site/index.html"
