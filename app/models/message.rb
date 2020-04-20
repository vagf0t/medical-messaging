class Message < ApplicationRecord
  belongs_to :inbox
  belongs_to :outbox
  attr_accessor :original_message_id
  scope :unread, -> { where(read: false) }
  WEEK = 7

  def self.build(body, original_message_id)
    message = Message.new(body: body, original_message_id: original_message_id)
    message.outbox = User.current.outbox
    message.set_inbox
    message
  end

  def set_inbox
    original_message = prevent_hacks(@original_message_id)
    days_since_original_message = (DateTime.now.to_date - original_message.created_at.to_date).to_i
    self.inbox = if days_since_original_message <= WEEK
                   User.default_doctor.inbox
                 else
                   User.default_admin.inbox
                 end
  end

  def set_to_read
    unless read?
      self.read = true
      inbox.update_unread if save
    end
  end

  def self.build_prescription_request(original_message_id)
    message = Message.new(body: "I've lost my script, please issue a new one at a charge of €10. Message: #{original_message_id}")
    message.outbox = User.current.outbox
    message.inbox = User.default_admin.inbox
    message
  end

  def self.request_prescription(original_message_id)
    Payment.transaction do
      payment = Payment.new(user: User.current)
      result = { id: '', notice: '' }
      if payment.save
        message = Message.build_prescription_request(original_message_id)
        message.prevent_hacks(original_message_id)
        if message.save
          if PaymentProviderFactory.debit_card(User.current)
            result[:id] = original_message_id
            result[:notice] = 'Your request was received! Your prescription will be sent to your inbox.'
          else
            # Try again in 15 minutes. We do not want to lose the payment.
            Message.delay(run_at: 15.minutes.from_now).request_prescription
            raise ActiveRecord::Rollback, 'Call to Payment API failed!'
          end
        else
          # Try again 15 minutes. We do not want to lose the payment.
          Message.delay(run_at: 15.minutes.from_now).request_prescription
          raise ActiveRecord::Rollback, 'Prescription request failed!'
        end
      else
        # Try again 15 minutes. We do not want to lose the payment.
        Message.delay(run_at: 15.minutes.from_now).request_prescription
        raise ActiveRecord::Rollback, 'Payment failed!'
      end
      result
    end
  end

  def prevent_hacks(original_message_id)
    raise OriginalMessageNotFound if original_message_id.blank?

    original_message = Message.find(original_message_id)
    if original_message.nil? ||
       original_message.inbox.user != self.outbox.user ||
       original_message.outbox != User.default_doctor.outbox
      raise HackAttempt
    end

    original_message
  end
end
