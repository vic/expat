defmodule Expat.Test do
  use ExUnit.Case
  doctest Expat

  import Expat

  defpat has_email %{"email" => email}
  defpat has_password %{"password" => password}
  defpat login has_email() = has_password()

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

  test "can match ignoring all variables" do
    assert login(_) = %{"email" => "foo", "password" => "bar"}
  end

  test "can match with focus on particular var" do
    assert login(password: "bar") = %{"email" => "foo", "password" => "bar"}
  end

  test "can match with all variables" do
    assert login(...) = %{"email" => "foo", "password" => "bar"}
    assert email == "foo"
    assert password == "bar"
  end

  defpat nerd %{"iq" => iq}
  defpat email %{"email" => email}
  defpat latlng %{"latitude" => lat, "longitude" => lng}

  test "zombies example" do
    juicy = %{"iq" => 210, "email" => "terry.tao@example.com",
              "latitude" => 19.0, "longitude" => 20.0}
    # match two patterns at once, bind all variables
    assert nerd() = latlng() = juicy
    assert iq == 210
    assert lat == 19.0
    assert lng == 20.0
  end

  test "can use patterns to create data" do
    dude = Map.merge(nerd(220), latlng(lat: 10, lng: 20))
    assert %{"latitude" => 10, "iq" => 220} = dude
  end

end

