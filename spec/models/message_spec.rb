require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:message_to_store) { Message.new(body: "Thanks for your order", outbox_id: 2, inbox_id: 1) }
  let(:message) { Message.new(original_message_id: -1) }
  let(:count) { User.default_doctor.inbox.messages.unread.count }
  let(:prescription_request) {Message.build_prescription_request(1)}

  it 'is created with unread status' do
    message_to_store.save!
    expect(message_to_store.read).to eq false
  end

  context 'sooner than week' do
    before do
      allow(subject).to receive(:created_at).and_return(Date.today - 7.days)
      allow(message).to receive(:prevent_hacks).and_return(subject)
    end

    it 'should send the email to the dr' do
      message.set_inbox
      expect(message.inbox.id).to eq User.default_doctor.inbox.id
    end
  end

  context 'later than week' do
    before do
      allow(subject).to receive(:created_at).and_return(Date.today - 8.days)
      allow(message).to receive(:prevent_hacks).and_return(subject)
    end

    it 'should send the email to the admin' do
      message.set_inbox
      expect(message.inbox.id).to eq User.default_admin.inbox.id
    end
  end

  context 'a user tries to reply without original message' do
    it 'should raise a OriginalMessageWasNotFound error' do
      expect { message_to_store.set_inbox }.to raise_error(OriginalMessageNotFound)
    end
  end

  context 'a user tries to reply to a non existent message' do
    it 'should raise a HackAttempt error' do
      message_to_store.original_message_id = -1
      allow(Message).to receive(:find)
      expect { message_to_store.set_inbox }.to raise_error(HackAttempt)
    end
  end

  context 'a user tries to reply to an other user`s message' do
    it 'should raise a HackAttempt error' do
      message_to_store.original_message_id = -1
      message.inbox = User.default_admin.inbox
      allow(Message).to receive(:find).and_return message
      expect { message_to_store.set_inbox }.to raise_error(HackAttempt)
    end
  end

  context 'a user tries to reply to a non dr message' do
    it 'should raise a HackAttempt error' do
      message_to_store.original_message_id = -1
      message.outbox = User.default_admin.outbox
      message.inbox = message_to_store.inbox
      allow(Message).to receive(:find).and_return message
      expect { message_to_store.set_inbox }.to raise_error(HackAttempt)
    end
  end

  context 'a dr receives an email' do
    it 'should update the unread emails' do
      expect(count).to eq 0
      User.default_doctor.inbox.messages << message_to_store
      User.default_doctor.inbox.update_unread
      expect(User.default_doctor.inbox.unread_emails).to eq 1
    end
  end

  context 'a dr opens an email' do
    it 'should update the unread emails' do
      expect(count).to eq 0
      User.default_doctor.inbox.messages << message_to_store
      User.default_doctor.inbox.update_unread
      expect(User.default_doctor.inbox.unread_emails).to eq 1
      User.default_doctor.inbox.messages.unread.last.set_to_read
      expect(User.default_doctor.inbox.unread_emails).to eq 0
    end
  end

  context 'a user receives an email' do
    it 'does not bother to update the unread emails' do
      expect(count).to eq 0
      User.current.inbox.messages << message_to_store
      User.current.inbox.update_unread
      expect(User.current.inbox.unread_emails).to be nil
    end
  end

  context 'a user opens an email' do
    it 'does not bother to update the unread emails' do
      expect(count).to eq 0
      User.current.inbox.messages << message_to_store
      User.current.inbox.update_unread
      expect(User.current.inbox.unread_emails).to be nil
      User.current.inbox.messages.unread.last.set_to_read
      expect(User.current.inbox.unread_emails).to be nil
    end
  end

  context 'build prescription request' do
    it 'has proper message body' do
      expect(prescription_request.body).to eq "I've lost my script, please issue a new one at a charge of €10. Message: 1"
    end

    it 'has proper inbox' do
      expect(prescription_request.inbox).to eq User.default_admin.inbox
    end

    it 'has proper outbox' do
      expect(prescription_request.outbox).to eq User.current.outbox
    end
  end

  context 'request_prescription' do
    it 'sends the prescription request to the admin' do
      expect(User.default_admin.inbox.messages).to be_empty
      expect(PaymentProviderFactory).to receive(:debit_card).with(User.current).and_call_original
      expect_any_instance_of(Message).to receive(:prevent_hacks)
      Message.request_prescription(1)
      expect(User.default_admin.inbox.messages.count).to eq 1
      expect(Payment.count).to eq 1
    end

    it 'enques a delayed job to repeat the request, if payment creation fails' do
      expect(User.default_admin.inbox.messages).to be_empty
      expect_any_instance_of(Payment).to receive(:save).and_return false
      expect(PaymentProviderFactory).not_to receive(:debit_card).with(User.current).and_call_original
      expect(Message).to receive(:delay).and_call_original
      Message.request_prescription(1)
      expect(User.default_admin.inbox.messages).to be_empty
      expect(Payment.count).to eq 0
    end

    it 'enques a delayed job to repeat the request, if message creation fails' do
      expect(User.default_admin.inbox.messages).to be_empty
      expect_any_instance_of(Message).to receive(:save).and_return false
      expect(PaymentProviderFactory).not_to receive(:debit_card).with(User.current).and_call_original
      expect(Message).to receive(:delay).and_call_original
      expect_any_instance_of(Message).to receive(:prevent_hacks)
      Message.request_prescription(1)
      expect(User.default_admin.inbox.messages).to be_empty
      expect(Payment.count).to eq 0
    end


    it 'enques a delayed job to repeat the request, if payment API call fails' do
      expect(User.default_admin.inbox.messages).to be_empty
      expect(PaymentProviderFactory).to receive(:debit_card).and_return false
      expect(Message).to receive(:delay).and_call_original
      expect_any_instance_of(Message).to receive(:prevent_hacks)
      Message.request_prescription(1)
      expect(User.default_admin.inbox.messages).to be_empty
      expect(Payment.count).to eq 0
    end
  end
end
