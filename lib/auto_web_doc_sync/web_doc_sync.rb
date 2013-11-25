require 'fileutils'
require 'yaml'
require 'net/http'
require 'uri'
require 'open3'
require 'logger'

require_relative 'util'

module AutoWebDocSync


class WebDocSync
  include Util

  NOTIFY_CMD = "/usr/local/bin/terminal-notifier"

  def initialize(options, log_path)
    options = symbolize_keys(options)
    @name = options[:name]
    @web_doc_base_url = options[:web_doc_base_url]
    @web_doc_file_names = options[:web_doc_file_names]

    @sync_dir_path = options[:sync_dir_path]
    @sync_file_name = (options[:sync_file_name] || ".#{@name}.yml")
    @sync_data_path = File.join(@sync_dir_path, @sync_file_name)

    # .sync_data.yml format
    #  web_docs:
    #    - file_name: redshift-gsg.pdf
    #      size: 122422
    #      last_modified: Wed, 16 Oct 2013 21:30:22 GMT
    @sync_data = if File.exists?(@sync_data_path)
                   YAML.load(File.read(@sync_data_path))
                 else
                   {"web_docs" => []}
                 end
    @web_docs = @sync_data['web_docs']

    FileUtils.mkdir_p(@sync_dir_path)

    log_path = STDOUT unless log_path
    $log = Logger.new(log_path)
    $log.level = case options[:log_level].to_s.upcase
                 when "DEBUG"; Logger::INFO
                 when "WARN";  Logger::WARN
                 when "ERROR"; Logger::ERROR
                 else; Logger::INFO
                 end
  end

  def check_and_update_all_docs(notify = true)
    $log.info("Start checking docs. name:\"#{@name}\" -> #{@sync_dir_path}")
    updated_files = @web_doc_file_names.select do |file_name|
      check_and_update_doc(file_name)
    end
    notify_updated_files(updated_files) if updated_files.size > 0 and notify
  rescue => e
    $log.error("Failed checking docs. error:#{e} error_class:#{e.class} backtrace:\n#{e.backtrace.join("\n")}")
    raise e
  end

  def check_and_update_doc(file_name)
    rdi = remote_doc_info(file_name)
    ldi = local_doc_info(file_name)
    unless rdi == ldi
      $log.debug "Downloading file:\"#{file_name}\" last-modified:\"#{rdi['last-modified']}\" -> #{build_save_path(file_name)}"
      download(file_name)
      update_sync_data(rdi)
      $log.info "Complted downloading file:\"#{file_name}\" last-modified:\"#{rdi['last-modified']}\" -> #{build_save_path(file_name)}"
      return true
    end
    $log.debug "Skip downloading file:\"#{file_name}\" last-modified:\"#{rdi['last-modified']}\" -> #{build_save_path(file_name)}"
    false
  end


  private

  def save_sync_data
    File.open(@sync_data_path, 'w') {|f| f.write @sync_data.to_yaml}
  end

  def local_doc_info(file_name)
    @web_docs.find {|d| d['file_name'] == file_name}
  end

  def build_url(file_name)
    if file_name.start_with?("http")
      file_name
    else
      "#{@web_doc_base_url}/#{file_name}"
    end
  end

  def build_save_path(file_name)
    File.join(@sync_dir_path, File.basename(file_name))
  end

  def request_head(url)
    uri = URI(url)
    response = nil
    Net::HTTP.start(uri.host, 80) {|http|
      response = http.head(uri.path)
    }
    response
  end

  def remote_doc_info(file_name)
    url = build_url(file_name)
    h = request_head(url).to_hash
    {
      'file_name' => file_name,
      'content-length' => h['content-length'].first,
      'last-modified' => h['last-modified'].first
    }
  end

  def download(file_name)
    uri = URI(build_url(file_name))
    Net::HTTP.start(uri.host, 80) do |http|
      resp = http.get(uri.path)
      open(build_save_path(file_name), "wb") do |file|
        file.write(resp.body)
      end
    end
  end

  def update_sync_data(remote_doc_info)
    file_name = remote_doc_info['file_name']
    ldi = local_doc_info(file_name)
    if ldi
      ldi.merge!(remote_doc_info)
    else
      @web_docs << remote_doc_info
    end
    save_sync_data
  end

  def exist_command?(command)
    begin
      Open3.capture3("type #{command}")[2].exited?
    rescue Errno::ENOENT
      false
    end
  end

  def notify_updated_files(updated_files)
    return unless exist_command?(NOTIFY_CMD)
    title = "#{@name} docs were updated!"
    msg = "Updated files: #{updated_files.join(', ')}"
    `#{NOTIFY_CMD} -title '#{title}' -message '#{msg}' -execute 'open #{@sync_dir_path}'`
  end
end


end
