defmodule Expat.Readme do
  @readme File.read!(Path.expand("../../README.md", __DIR__))
  @external_resource @readme
  @moduledoc @readme
end
