defmodule CliTest do
  use ExUnit.Case
  doctest Issues
  import Issues.CLI, only: [parse_args: 1]

  test ":help ret by option parsing with -h and --help options" do
    assert parse_args(["-h", "anything"]) == :help
    assert parse_args(["-help", "anything"]) == :help
  end

  test "3 vals ret if 3 given" do
    assert parse_args(["user", "project", "99"]) == {"user", "project", 99}
  end

  test "count is def if 2 vals given" do
    assert parse_args(["user", "project"]) == {"user", "project", 4}
  end

end
