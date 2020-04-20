class PaymentProviderFactory
  # def self.provider
  #   @provider ||= Provider.new
  # end

  def self.debit_card(user)
    true
  end;
end
