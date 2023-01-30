#!/usr/bin/env bash
set -e
mkdocs build
aws s3 sync site/ s3://boxy-website --delete
aws cloudfront create-invalidation --distribution-id ENR9INMU9EWHN --paths "/*"
