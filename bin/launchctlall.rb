#!/usr/bin/env ruby

require 'yaml'
require 'erb'

HOME_DIR = File.absolute_path(File.dirname(File.dirname(__FILE__)))
SCRIPTS_DIR = File.join(HOME_DIR, 'script')
SCRIPTS_CONF_DIR = File.join(HOME_DIR, 'script_conf')
SCRIPTS_LOG_DIR = File.join(HOME_DIR, 'script_log')
CONFS_DIR = File.join(HOME_DIR, 'conf')
PLISTS_DIR = File.join(HOME_DIR, 'plist')
SETTING_FILE = File.join(CONFS_DIR, 'settings.yml')

@settings = YAML.load(ERB.new(File.read(SETTING_FILE)).result)
@default_setting = @settings['default']
@scripts = @settings['scripts']
@scripts = @scripts.collect do |s|
  h = @default_setting.merge(s)
  h['launchctl_parameters'] = @default_setting['launchctl_parameters'].merge(h['launchctl_parameters'])
  unless h['launchctl_parameters']['Label']
    h['launchctl_parameters']['Label'] = h['name']
  end
  h
end
@names = @settings['scripts'].collect do |s|
  raise "name is required in settings.yml." if s['name'].to_s == ''
  s['name']
end
unless @names.uniq.count == @settings['scripts'].count
  raise "name is not uniq in settings.yml."
end

def usage
  puts <<EOT
  launchctlall is a wrapper tool of launchctl.
  usage: ./launchctlall [command]
    [command]
      - list      show loaded setting files
      - list_all  show all loaded setting files
      - load      update and load setting files
      - unload    unload setting files
      - update    update setting files
EOT
  exit 1
end

def script_conf_path(script)
  script['script_conf_path'] || (File.join(SCRIPTS_CONF_DIR, script['name']) + ".yml")
end

def script_log_path(script)
  script['script_log_path'] || (File.join(SCRIPTS_LOG_DIR, script['name']) + ".log")
end

def plist_path(script)
  File.join(PLISTS_DIR, script['name'] + ".plist")
end

def run_launchctl(args_str)
  puts `launchctl #{args_str}`
end

def load_scripts(scripts)
  scripts.each do |s|
    cmd = if s['enabled'] == false
            'unload'
          else
            'load'
          end
    run_launchctl("#{cmd} #{plist_path(s)}")
  end
end

def run_launchctl_with_scripts(cmd, scripts)
  scripts.each do |s|
    run_launchctl("#{cmd} #{plist_path(s)}")
  end
end

def plist_content(script)
  script_path = (script['script_path'] || (File.join(SCRIPTS_DIR, script['script_name'])))
  other_parameters = script['launchctl_parameters'].inject('') do |str, (k, v)|
    type = case v
           when true, false; 'boolean'
           when Integer; 'integer'
           when Float; 'float'
           else; 'string'
           end
    value_part = (type == 'boolean') ? "<#{v.to_s}/>" : "<#{type}>#{v}</#{type}>"
    str << "  <key>#{k}</key>\n  #{value_part} \n"
  end
  <<EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>ProgramArguments</key>
  <array>
    <string>#{script_path}</string>
    <string>#{script_conf_path(script)}</string>
    <string>#{script_log_path(script)}</string>
  </array>
#{other_parameters}
</dict>
</plist>
EOT
end

def generate_script_conf(script)
  File.open(script_conf_path(script), 'w') do |f|
    f.write(YAML.dump(script))
  end
end

def generate_all_script_confs(scripts)
  scripts.each {|s| generate_script_conf(s)}
end

def generate_plist(script)
  File.open(plist_path(script), 'w') do |f|
    f.write(plist_content(script))
  end
end

def generate_all_plists(scripts)
  scripts.each {|s| generate_plist(s)}
end

def generate_all_setting_files(scripts)
  generate_all_script_confs(scripts)
  generate_all_plists(scripts)
end

# main
cmd = ARGV[0]
case cmd
when 'update'
  generate_all_setting_files(@scripts)
when 'load'
  generate_all_setting_files(@scripts)
  load_scripts(@scripts)
when 'unload'
  run_launchctl_with_scripts(cmd, @scripts)
when 'list'
  @names.collect do |name|
    run_launchctl("list | grep #{name}")
  end
when 'list_all'
  run_launchctl('list')
else
  usage
end
