#!/bin/sh

if [ -d docs ]; then
  rm -rf docs
fi

jazzy \
--clean \
--author "Hituzi Ando" \
--author_url https://hituzi-ando.com/ \
--build-tool-arguments -scheme,kamome \
--output docs/
