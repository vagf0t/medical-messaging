class Inbox < ApplicationRecord

  belongs_to :user
  has_many :messages
  
  def update_unread
    if user == User.default_doctor # <-- omit this check, to update all inboxes
      self.unread_emails = messages.unread.count
      save!
    end
  end
end