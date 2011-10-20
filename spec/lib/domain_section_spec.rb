require 'domain_section'

describe DomainSection do
  it "handles bare domains" do
    DomainSection.new('example.org').variants.should eq(['example.org'])
  end

  it "strips off http://" do
    DomainSection.new('http://example.org').variants.should eq(['example.org'])
  end

  it "strips off https://" do
    DomainSection.new('https://example.org').variants.should eq(['example.org'])
  end

  it "handles sub domain" do
    DomainSection.new('www.example.org').variants.should eq(['example.org', 'www.example.org'])
  end

  it "handles bare domains with many segments" do
    DomainSection.new('foo.bar.baz.example.org').variants.should eq(['example.org', 'baz.example.org', 'bar.baz.example.org', 'foo.bar.baz.example.org'])
  end
end

