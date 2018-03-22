defmodule Expat.ResultTest do
  use ExUnit.Case
  use Expat

  @moduledoc ~S"""
  Example Result as requested by @OvermindDL1

  This example defines a Union Pattern for working
  witk ok/error tagged tuples.

  A better Result type would be actually more
  similar to Either (see expat_either_test.exs).
  Just having two constructors.

  However, since Elixir/Erlang custom is to use
  tagged tuples but also the `:ok` and `:error`
  atoms by themselves, we are including more
  type constructors.

  Our `result` head pattern takes advantage of the
  fact that we are using tagged tuples or plain atoms
  to restrict values that can be a result.
  """


  # Atoms or tuples having :ok/:error as first element
  # are considered results.
  defguard is_result(r) when r == :ok or r == :error or
  elem(r, 0) == :ok or elem(r, 0) == :error

  defpat (result(r) when is_result(r))
  | ok_only(:ok)
  | error_only(:error)
  | ok({:ok, value})
  | error({:error, reason})
  | ok2({:ok, value, meta})
  | error2({:error, reason, meta})

  test "ok_only is just an atom" do
    assert :ok = ok_only!()
  end

  test "error is a tagged tuple" do
    assert {:error, "Fail"} = error!("Fail")
  end

  test "error2 is also a tagged tuple and valid result type" do
    assert {:error, _, _} = error2!(:enoent, "/file")
  end

  test "ok_only can be used to match" do
    expat case :ok do
            ok_only() -> assert :good
          end
  end

  test "ok can be used to match and extract" do
    expat case {:ok, "good"} do
            ok(res) -> assert "good" == res
          end
  end


  test "error2 can be used to match and extract" do
    expat case {:error, :enoent, "/file"} do
            error2(:enoent, file) -> assert "/file" == file
          end
  end

end
