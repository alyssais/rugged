require File.expand_path "../test_helper", __FILE__
require 'base64'

context "Rugged::Repository stuff" do
  setup do
    @path = File.dirname(__FILE__) + '/fixtures/testrepo.git/'
    @repo = Rugged::Repository.new(@path)

    @test_content = "my test data\n"
    @test_content_type = 'blob'
  end

  test "fails to open unexisting repositories" do
    assert_raise RuntimeError do
      repo = Rugged::Repository.new("fakepath/123/")
    end

    assert_raise RuntimeError do
      repo = Rugged::Repository.new("/home/")
    end
  end

  test "can tell if an object exists or not" do
    assert @repo.exists("8496071c1b46c854b31185ea97743be6a8774479")
    assert @repo.exists("1385f264afb75a56a5bec74243be9b367ba4ca08")
    assert !@repo.exists("ce08fe4884650f067bd5703b6a59a8b3b3c99a09")
    assert !@repo.exists("8496071c1c46c854b31185ea97743be6a8774479")
  end

  test "can read an object from the db" do
    rawobj = @repo.read("8496071c1b46c854b31185ea97743be6a8774479")
    assert_match 'tree 181037049a54a1eb5fab404658a3a250b44335d7', rawobj.data
    assert_equal 172, rawobj.len
    assert_equal :commit, rawobj.type
  end

  test "checks that reading fails on unexisting objects" do
    assert_raise RuntimeError do 
      @repo.read("a496071c1b46c854b31185ea97743be6a8774471")
    end
  end

  test "can hash data" do
    oid = Rugged::Repository::hash(@test_content, @test_content_type)
    assert_equal "76b1b55ab653581d6f2c7230d34098e837197674", oid
  end

  test "can write to the db" do
    oid = @repo.write(@test_content, @test_content_type)
    assert_equal "76b1b55ab653581d6f2c7230d34098e837197674", oid
    assert @repo.exists("76b1b55ab653581d6f2c7230d34098e837197674")

    rm_loose(oid)
  end

  test "can use the builtin walk method" do
    oid = "a4a7dce85cf63874e984719f4fdd239f5145052f"
    list = []
    @repo.walk(oid) { |c| list << c }
    assert list.map {|c| c.oid[0,5] }.join('.'), "a4a7d.c4780.9fd73.4a202.5b5b0.84960"
  end

  test "can lookup head from repo" do
    head = @repo.head
    assert_equal "36060c58702ed4c2a40832c51758d5344201d89a", head.target
    assert_equal :direct, head.type
  end

  test "garbage collection methods don't crash" do
    Rugged::Repository.new(@path)
    ObjectSpace.garbage_collect
  end

end
