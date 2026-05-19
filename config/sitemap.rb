# frozen_string_literal: true

# Local debug only (writes public/sitemap.xml.gz, gitignored).
# Production serves GET /sitemap.xml.gz via SitemapsController.
Sitemap::Builder.write!(Rails.root.join("public", "sitemap.xml.gz"))
