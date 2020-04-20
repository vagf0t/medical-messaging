class OriginalMessageNotFound < StandardError
  def message
    'Original message was not found.'
  end
end