module RecordsHelper
  def download_link(record)
    link_to 'Download', record_path(record, download_content: true) if can?(:show, record)
  end
end
