class CreateUsersMessagesInboxesOutboxesAndPayments < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.boolean :is_patient, default: true
      t.boolean :is_doctor, default: false
      t.boolean :is_admin, default: false
      t.string :first_name
      t.string :last_name
      t.timestamps
    end

    create_table :messages do |t|
      t.text :body
      t.references :outbox
      t.references :inbox
      t.boolean :read, default: false
      t.timestamps
    end

    create_table :inboxes do |t|
      t.references :user
    end

    create_table :outboxes do |t|
      t.references :user
    end

    create_table :payments do |t|
      t.references :user
    end
  end
end
