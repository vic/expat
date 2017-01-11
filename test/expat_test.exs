defmodule Expat.Test do
  use ExUnit.Case
  doctest Expat

  import Expat

  defpat has_email %{"email" => email}
  defpat has_password %{"password" => password}
  defpat login has_email(...) = has_password(...)

  test "creates all variables if given empty list" do
    assert has_email() = %{"email" => "foo"}
    assert "foo" == email
  end

  test "ignores variables" do
    assert has_email(_) = %{"email" => "foo"}
  end

  test "creates only variables given as parameters" do
    assert has_email(email: addr) = %{"email" => "foo"}
    assert "foo" == addr
  end

  test "can combine" do
    assert login(_) = %{"email" => "foo", "password" => "bar"}
  end

  test "can combine ss" do
    assert login(password: "bar") = %{"email" => "foo", "password" => "bar"}
  end

  test "can combine sa" do
    assert login() = %{"email" => "foo", "password" => "bar"}
    assert email == "foo"
    assert password == "bar"
  end

end

