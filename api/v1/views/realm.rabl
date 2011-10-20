object @realm
attributes :label
code(:domains){ @realm.domains.map(&:name) }
