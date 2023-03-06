defmodule Classifier do
  def grayscale(img) do
    Evision.cvtColor(img, Evision.Constant.cv_COLOR_BGR2GRAY())
  end
  def read(path) do
    Evision.imread(path)
  end
  def resize(img) do
    Evision.resize(img, {300, 300})
  end
  def denoise(img) do
    Evision.fastNlMeansDenoising(img)
  end
  def threshold(img, threshold\\127) do
    {_, img} = Evision.threshold(img, threshold, 255, Evision.Constant.cv_THRESH_BINARY())
    img
  end
  def preprocess(img) do
    img
    |> grayscale
    |> resize
    |> denoise
    |> threshold
  end
  def convert_to_nx(img) do
    Evision.Mat.to_nx(img, Nx.BinaryBackend)
  end
  #find array of the image with x coordinate x
  def x_arr(img_arr, x) do
    img_arr[x]
  end

  def y_arr(img_arr, y) do
    img_arr[[0..-1//1, y]]
  end

  def checker(arr) do
    part1 = arr[[0..89//1]]
    part2 = arr[[90..209//1]]
    part3 = arr[[210..299//1]]
    mid_mean = Nx.mean(part2) |> Nx.to_number
    rest_mean = Nx.concatenate([part1, part3]) |> Nx.mean |> Nx.to_number
    IO.puts "mid_mean: #{mid_mean}"
    IO.puts "rest_mean: #{rest_mean}"
    if (mid_mean - rest_mean) > 30 do
      1
    else
      0
    end
  end
  def func(img_arr) do
    arr = [x_arr(img_arr, 15), x_arr(img_arr, 275), y_arr(img_arr, 15), y_arr(img_arr, 275)]
    val =
    Enum.map(arr, &checker/1)
    |>
    Enum.count(&(&1 == 1))
    if val > 2 do
      "JUNCTION"
    else
      "NOT JUNCTION"
    end
  end
  def predict(path) do
    read(path)
    |> preprocess
    |> convert_to_nx
    |> func
  end
  def write(img) do
    img = grayscale(img)
    img = resize(img)
    img = denoise(img)
    img = threshold(img)
    Evision.imwrite("test.jpg", img)
  end
end
