require 'test/unit'

class Test::Unit::TestCase
  def test_require_package
    assert require('package')
  end

  def test_require_package_conf
    assert require('package/conf')
  end
end
