defmodule ScheduleWebWeb.InputHelpers do
  use Phoenix.HTML

  def weekday_input(form, field) do
    type = Phoenix.HTML.Form.input_type(form, field)
    values = Phoenix.HTML.Form.input_value(form, field) || [""]

    input_opts = [value: values |> Enum.join(", ")]

    apply(Phoenix.HTML.Form, type, [form, field, input_opts])
  end
end
