class AddUnreadEmailsToInboxes < ActiveRecord::Migration[5.0]
  def change
    add_column :inboxes, :unread_emails, :integer
  end
end
