object false
child @realm do
  attributes :label
  code(:domains){ @realm.domains.map(&:name) }
end

child @identity, :if => !!@identity do
  extends 'identity'
end

child @session, :if => !!@session do
  attributes :key
end

child @sessions, :if => !!@sessions do
  attributes :key
end
