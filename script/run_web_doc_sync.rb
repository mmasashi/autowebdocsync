#!/usr/bin/env ruby

lib = File.expand_path(File.dirname(__FILE__) + '/../lib')
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'auto_web_doc_sync'
require 'yaml'

# parse arguments
exit 1 unless yaml_conf_path = ARGV[0]

AutoWebDocSync::WebDocSync.new(
  YAML::load(File.open(yaml_conf_path)), ARGV[1]
).check_and_update_all_docs

