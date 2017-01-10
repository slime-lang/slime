defmodule Slime.Doctype do
  @moduledoc """
  Mapping doctype shorthands to their actual values.
  """

  def for("1.1"),
    do: ~S[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">]

  def for("html"),
    do: "<!DOCTYPE html>"

  def for("5"),
    do: "<!DOCTYPE html>"

  def for("basic"),
    do: ~S[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">]

  def for("frameset"),
    do: ~S[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">]

  def for("mobile"),
    do: ~S[<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">]

  def for("strict"),
    do: ~S[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">]

  def for("transitional"),
    do: ~S[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">]

  def for("xml ISO-8859-1"),
    do: ~S[<?xml version="1.0" encoding="iso-8859-1" ?>]

  def for("xml"),
    do: ~S[<?xml version="1.0" encoding="utf-8" ?>]
end
