class HackAttempt < StandardError
  def message
    'Original message was not the expected one.'
  end
end