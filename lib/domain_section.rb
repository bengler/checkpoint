class DomainSection

  attr_reader :variants
  def initialize(url)
    @segments = url.gsub(/https?:\/\//, '').split('.')
    @components = compose
    @variants = @components.map {|component| component.join('.')}
  end

  def compose
    segments = @segments.dup
    components = [segments.slice!(-2..-1)]
    until segments.empty?
      components << components.last.dup.unshift(segments.pop)
    end
    components
  end
end
