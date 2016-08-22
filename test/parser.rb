assert('JSON::Expect::Parser') do
  begin
    e = JSON::Expect::Parser.new(%({"hello": "world"}))
    e.object do
      assert_equal "hello", e.key
      assert_equal "world", e.string
    end
  rescue => e
    puts e.backtrace
    raise
  end
end
