json.type :Person
json.extract! person, :id, :account_name, :first_name, :last_name,
	:email_address, :birthday, :gender, :joined, :quitted, :active
json.extract! person, :railway_station, :railway_discount, :meal_preference, :comment
json.extract! person, :newsletter, :photos_allowed, :publish_birthday, :publish_email, :publish_address, :publish
json.extract! person, :paid_until, :member?
json.url person_url(person, format: :json)

if modules.include? :addresses
	json.addresses do
		json.array! person.addresses, partial: 'addresses/address', as: :address
	end
end
if modules.include? :contacts
	json.contacts do
		json.array! person.contacts, partial: 'contacts/contact', as: :contact
	end
end
if modules.include? :payments
	json.payments do
		json.array! person.payments, partial: 'payments/payment', as: :payment
	end
end
if modules.include? :registrations
	json.registrations_summary do
		json.array! person.registrations, partial: 'registrations/registration_summary_for_person',
			as: :registration
	end
end
if modules.include? :sepa_mandate
	json.sepa_mandate do
		json.type :SepaMandate
		json.extract! person.sepa_mandate, :id, :mandate_reference, :signature_date, :iban, :bic, :name_account_holder
	end
end
