module Seed

  class << self
    def create_realm(label, options = {})
      Realm.where(:label => label).each do |realm|
        realm.domains.destroy_all
        realm.identities.each do |identity|
          identity.sessions.destroy_all
          identity.accounts.destroy_all
          identity.destroy
        end
      end

      title = options[:title] || label.capitalize
      domain = options[:domain] || "#{label}.dev"
      keys = options[:keys] || {}
      realm = Realm.create!(:label => label, :title => title, :service_keys => YAML.dump(keys))
      domain = Domain.create!(:name => domain, :realm => realm)
      realm.primary_domain_id = domain.id
      realm.save

      identity = Identity.create!(:realm => realm, :god => options[:god])
      Session.create!(:identity => identity)
      realm
    end

    def explain(realm, out = STDOUT)
      out << "* #{realm.label}\n"
      out << "    Primary domain: #{realm.primary_domain and realm.primary_domain.name}\n"
      out << "    Domains:\n"
      realm.domains.each do |domain|
        out << "\t#{domain.name}\n"
      end
      out << "    God sessions:\n"
      realm.identities.where(:god => true).each do |identity|
        Session.where(:identity_id => identity.id).each do |session|
          out << "\t#{session.key}\n"
        end
      end
      out << "\n"
    end

    def list(out = STDOUT)

      Realm.all.each do |realm|
        explain(realm, out)
      end

    end
  end

end
