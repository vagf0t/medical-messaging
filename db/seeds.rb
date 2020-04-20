# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

patient = User.create(first_name: 'Luke', last_name: 'Skywalker', inbox: Inbox.new, outbox: Outbox.new)
doctor = User.create(first_name: 'Leia', last_name: 'Organa', is_doctor: true, is_patient: false, inbox: Inbox.new, outbox: Outbox.new)
admin = User.create(first_name: 'Obi-wan', last_name: 'Kenobi', is_admin: true, is_patient: false, inbox: Inbox.new, outbox: Outbox.new)

Message.create(body: 'Thanks for your order. I will in touch shortly after reviewing your treatment application.',
               outbox: doctor.outbox,
               inbox: patient.inbox)
