defmodule YOhello do
  def yo do
    :yo
  end
end
defmodule Hello do
  def hello1 do
    :hello1
  end
  def hello2 do
    YOhello.yo()
  end
end
