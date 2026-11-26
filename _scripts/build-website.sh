#!/bin/bash
set -ex
export JEKYLL_ENV=production

# Update this and `version` in _configs/config_community_jdk25i.yml for next release
FEATURE_VERSION=25.6
FEATURE_SITE_PATH="jdk$FEATURE_VERSION"

# Build the libraries and frameworks page from the latest metadata
if [[ ! -d _graalvm-reachability-metadata ]]; then
  git clone --depth 1 https://github.com/oracle/graalvm-reachability-metadata.git _graalvm-reachability-metadata
fi
ruby _scripts/generate-library-and-framework-list.rb

# Build the latest documentation
# Build the non-versioned site and redirects for non-versioned URLs
./_scripts/pull-extra.sh "release/graal-vm/$FEATURE_VERSION"
ruby _scripts/process_front_matter.rb --add-title pages release-notes
ruby _scripts/process_front_matter.rb --add-title --add-version-to-permalinks --add-versioned-redirects docs truffle/docs espresso/docs web-image/docs pages/redirects
bundle exec jekyll build --config _configs/config_community_latest.yml

# Build the versioned feature release documentation
bundle exec jekyll build --destination "$FEATURE_SITE_PATH" --config _configs/config_community_jdk25i.yml
./_scripts/merge_sitemaps.rb _site/sitemap.xml "$FEATURE_SITE_PATH/sitemap.xml" "https://www.graalvm.org/$FEATURE_SITE_PATH/"
rsync -av "$FEATURE_SITE_PATH/$FEATURE_SITE_PATH" _site/
rsync -av --exclude "*.html" "$FEATURE_SITE_PATH/docs" _site/
rm -rf "$FEATURE_SITE_PATH"

# Build DEV documentation (always from master)
./_scripts/pull-extra.sh master
ruby _scripts/process_front_matter.rb --add-title --add-version-to-permalinks docs truffle/docs espresso/docs web-image/docs pages/redirects
bundle exec jekyll build --destination dev --config _configs/config_community_dev.yml
./_scripts/merge_sitemaps.rb _site/sitemap.xml dev/sitemap.xml https://www.graalvm.org/dev/
rsync -av dev/dev _site/
rsync -av --exclude "*.html" dev/docs _site/
rm -rf dev

mkdir -p _site/resources/js
printf '{\n  "siteVersion": "%s",\n  "label": "GraalVM %s (Innovation)"\n}\n' \
  "$FEATURE_SITE_PATH" "$FEATURE_VERSION" \
  > _site/resources/js/current-feature-version.json

# Restore source pages that process_front_matter.rb mutates while generating versioned redirects and canonical URLs
git checkout -- \
  pages/redirects/fastr.md \
  pages/redirects/graaljs.md \
  pages/redirects/graalpy.md \
  pages/redirects/graalwasm.md \
  pages/redirects/truffleruby.md \
  pages/ruby/ruby.md

echo "Website build completed successfully: _site/index.html"
