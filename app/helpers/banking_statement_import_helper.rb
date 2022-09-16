require 'csv'
require 'general_helpers'

module BankingStatementImportHelper
	include GeneralHelpers

	def banking_statement_import_link
		return unless policy(:database).import_banking_statement?
		link_to t('actions.import_banking_statements.prepare'), import_banking_statement_path
	end

	def parse_reference_line(reference)
		event_str, person_str = reference.split(",")
		if person_str.nil?
			raise "Verwendungszweck enthält kein Trennzeichen."
		end

		person = find_person(person_str.gsub(/ /, ''))

		if event_str.starts_with? "Mitgliedsbeitrag"
			year = Integer(event_str.match(/\d{4}/)[0])
			return {
				:type => :membership,
				:year => year,
				:person => person
			}
		end
		event = find_event(event_str)
		{
			:type => :event,
			:event => event,
			:person => person,
			:registration => Registration.find_by(event: event, person: person)
		}
	end

	def find_person(name)
		begin
			matches = Person.all.select {|person| (asciify(person.full_name)).gsub(/ /, '') == name}
			sole_element matches
		rescue Exception => e
			case e.message
			when "None"
				raise "Keine Person mit Namen #{name} gefunden."
			when "Multiple"
				raise "Mehrere Personen mit Namen #{name} gefunden."
			else
				raise "Unbekannter Fehler, bei Personensuche: #{e.message}"
			end
		end
	end

	def find_event(event_str)
		event_str.gsub!(/ /, '')
		unless event_str =~ /\d{4}/
			event_str.gsub!(/\d\d/) {|match| "20#{match}"}
		end
		begin
			sole_element Event.all.select {|event| event.reference_line.gsub(/ /, '') == event_str}
		rescue Exception => e
			case e.message
			when "None"
				raise "Keine Veranstaltung mit Namen #{name} gefunden."
			when "Multiple"
				raise "Mehrere Veranstaltungen mit Namen #{name} gefunden."
			else
				raise "Unbekannter Fehler, bei Veranstaltungssuche: #{e.message}"
			end
		end
	end

	def parse_line(line)
		{
			**parse_reference_line(line["Verwendungszweck"]),
			:amount => Float(line["Betrag"].gsub(/,/, '.')),
			:payment_date => DateTime.parse(line["Buchungstag"]),
		}
	end

	def validate_payment(payment)
		amount = payment[:amount]
		person = payment[:person]
		if payment[:type] == :membership
			unless Rails.configuration.membership_fee == amount
				raise "Mitgliedsbeitrag ist #{Rails.configuration.membership_fee} nicht #{amount}."
			end
			if person.paid_until >= DateTime.new(payment[:year]).end_of_year.yesterday
				raise "Person #{person.full_name} hat schon für das Jahr #{payment[:year]} gezahlt."
			end
		else
			event = payment[:event]
			registration = payment[:registration]
			if registration.nil?
				raise "Person #{person.full_name} nicht für die Veranstaltung #{event.title} angemeldet."
			end
			if registration.payment_complete
				raise "Person #{person.full_name} schon für die Veranstaltung #{event.title} bezahlt."
			end
			unless registration.money_amount == amount
				raise "Person #{person.full_name} muss #{registration.money_amount}€ für die Veranstaltung #{event.title} zahlen, nicht #{amount}€."
			end
		end
	end

	def apply_payment(payment)
		if payment[:type] == :membership
			year_date = DateTime.new(payment[:year])
			Payment.create(
				person: payment[:person],
				payment_type: :regular_member,
				start: year_date.beginning_of_year,
				end: year_date.end_of_year,
				amount: payment[:amount]
			)
			"Mitgliedschaft für #{payment[:person].full_name} für das Jahr #{payment[:year]} angelegt."
		else

			registration = payment[:registration]
			registration.payment_complete = true
			registration.money_transfer_date = payment[:payment_date]
			registration.save!
			"Veranstaltung #{payment[:event].title} für Person #{payment[:person].full_name} bezahlt."
		end
	end

	def handle_payment_record(record)
		begin
			payment = parse_line(record)
			validate_payment payment
			return apply_payment payment
		rescue Exception => e
			return e.message
		end
	end

	def import_banking_csv(data)
		records = CSV.parse(data, headers: true, col_sep: ";", strip: true)
		results = []
		ActiveRecord::Base.transaction do
			records.each {|record|
				results.push([record["Verwendungszweck"], record["Betrag"], handle_payment_record(record)])
			} unless records.nil?
		end
		results
	end
end
