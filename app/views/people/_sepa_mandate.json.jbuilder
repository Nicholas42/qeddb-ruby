if policy(person).view_sepa_mandate?
  json.sepa_mandate do
    if person.sepa_mandate.nil?
      json.nil!
    else
      json.extract! person.sepa_mandate, :mandate_reference, :signature_date, :iban, :bic, :name_account_holder
    end
  end
end
