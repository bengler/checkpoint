class DomainNameValidator < ActiveModel::Validator

  def validate(record)
    self.class.validate_name(record.name) do |error|
      record.errors.add(:name, error)
    end
  end

  def self.valid_name_or_ip?(string)
    validate_name(string) do |_|
      return false
    end
    true
  end

  # Is this an IPv4 address?
  def self.ip_address?(string)
    string =~ IP_ADDRESS_PATTERN
  end

  private

    def self.validate_name(name, &block)
      unless ip_address?(name)
        asciified = SimpleIDN.to_ascii(name)
        if asciified != name
          yield :must_be_idn
        end
        if asciified !~ RFC_NAME_PATTERN
          yield :dns_name_has_illegal_characters
        elsif name.length > RFC_NAME_LIMIT
          yield :dns_name_is_too_long
        elsif name.split('.').map(&:length).max > RFC_NAME_LABEL_LIMIT
          yield :dns_name_has_too_long_label
        end
      end
    end

    IP_ADDRESS_PATTERN = /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\z/.freeze

    RFC_NAME_PATTERN = /\A[*a-z0-9][a-z\.0-9-]+\z/ui.freeze
    RFC_NAME_LIMIT = 253
    RFC_NAME_LABEL_LIMIT = 63

end
