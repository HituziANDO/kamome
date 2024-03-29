#!/bin/sh

if [ -d docs ]; then
  rm -rf docs
fi

jazzy \
--clean \
--author "Hituzi Ando" \
--author_url https://hituzi-ando.app/ \
--build-tool-arguments -scheme,"kamome iOS" \
--output docs/
