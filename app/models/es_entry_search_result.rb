class EsEntrySearchResult < EsSearchResult

  def docket_id
    # Ensure interface matches with historical EntryApiRepresentation
    self['docket_id'].uniq.first
  end

  def docket_ids
    # Ensure interface matches with historical EntryApiRepresentation
    self['docket_id']
  end

  def full_text
    # full_text is excluded from ES source (too large); read from disk on demand
    return nil unless document_number.present? && publication_date.present?

    pub_date = publication_date.is_a?(String) ? Date.parse(publication_date) : publication_date
    doc_file_path = "#{pub_date.strftime('%Y/%m/%d')}/#{document_number}"
    path = "#{FileSystemPathManager.data_file_path}/documents/full_text/raw/#{doc_file_path}.txt"
    File.read(path) if File.file?(path)
  end

  def page_views
    BatchLoader.for(document_number).batch do |document_numbers, loader|
      PageViewCount.batch_count_for(document_numbers, PageViewType::DOCUMENT).each do |document_number, details|
        loader.call(document_number, details) 
      end
    end
  end

  def type
    entry_type #NOTE: The serializer/ES-stored "type" attribute is different than the "type" field returned in API requests, hence the override here.
  end

end
