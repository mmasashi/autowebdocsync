module AutoWebDocSync

  %w(
    web_doc_sync
    util
  ).each do |file|
    require_relative "auto_web_doc_sync/#{file}"
  end

end

