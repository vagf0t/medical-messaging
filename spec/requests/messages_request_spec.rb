require 'rails_helper'

RSpec.describe "Messages", type: :request do

  let(:message) { Message.create!(body: 'Thanks for your order', outbox_id: User.default_doctor.outbox.id, inbox_id: User.current.inbox.id, original_message_id: 1) }

  context 'GET #show' do
    it 'sets the message to read' do
      get "/messages/#{message.id.to_s}"
      expect(message.reload.read).to eq true
    end
  end

  context 'POST #create' do
    it 'increases dr`s unread messages' do
      expect(User.default_doctor.inbox.unread_emails).to eq nil
      post '/messages', params: { message: { body: 'Hello dr', outbox_id: User.current.outbox.id, inbox_id: User.default_doctor.inbox.id, original_message_id: message.id } }
      expect(User.default_doctor.inbox.unread_emails).to eq 1
      expect(response).to redirect_to message_path(id: User.current.inbox.messages.last.id)
    end
  end

  context 'POST #prescription' do
    it 'sends the prescription request to the admin' do
      expect(User.default_admin.inbox.messages).to be_empty
      expect(PaymentProviderFactory).to receive(:debit_card).with(User.current).and_call_original
      expect_any_instance_of(Message).to receive(:prevent_hacks)
      post '/messages/1/prescription', params: {original_message_id: 1}
      expect(User.default_admin.inbox.messages.count).to eq 1
      expect(Payment.count).to eq 1
      expect(response).to redirect_to message_path(id: 1)
    end

    it 'enques a delayed job to repeat the request, if payment creation fails' do
      expect(User.default_admin.inbox.messages).to be_empty
      expect_any_instance_of(Payment).to receive(:save).and_return false
      expect(PaymentProviderFactory).not_to receive(:debit_card).with(User.current).and_call_original
      expect(Message).to receive(:delay).and_call_original
      post '/messages/1/prescription', params: {original_message_id: 1}
      expect(User.default_admin.inbox.messages).to be_empty
      expect(Payment.count).to eq 0
      expect(response).to redirect_to root_path
    end

    it 'enques a delayed job to repeat the request, if message creation fails' do
      expect(User.default_admin.inbox.messages).to be_empty
      expect_any_instance_of(Message).to receive(:save).and_return false
      expect(PaymentProviderFactory).not_to receive(:debit_card).with(User.current).and_call_original
      expect(Message).to receive(:delay).and_call_original
      expect_any_instance_of(Message).to receive(:prevent_hacks)
      post '/messages/1/prescription', params: {original_message_id: 1}
      expect(User.default_admin.inbox.messages).to be_empty
      expect(Payment.count).to eq 0
      expect(response).to redirect_to root_path
    end


    it 'enques a delayed job to repeat the request, if payment API call fails' do
      expect(User.default_admin.inbox.messages).to be_empty
      expect(PaymentProviderFactory).to receive(:debit_card).and_return false
      expect(Message).to receive(:delay).and_call_original
      expect_any_instance_of(Message).to receive(:prevent_hacks)
      post '/messages/1/prescription', params: {original_message_id: 1}
      expect(User.default_admin.inbox.messages).to be_empty
      expect(Payment.count).to eq 0
      expect(response).to redirect_to root_path
    end
  end
end
