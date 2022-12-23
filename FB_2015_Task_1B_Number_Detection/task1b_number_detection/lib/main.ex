defmodule Main do
  alias Evision, as: Cv
  def grayscale(img) do
    Cv.cvtColor!(img, Cv.cv_COLOR_BGR2GRAY)
  end
  def gaussian_blur(img) do
    Cv.blur!(img, [5, 5])
  end
  def threshold(img) do
    {_, ret} = Cv.threshold!(img, 0, 255, Cv.cv_THRESH_BINARY + Cv.cv_THRESH_OTSU)
    ret
  end
  def adaptive_threshold(img) do
    Cv.adaptiveThreshold!(img, 255, Cv.cv_ADAPTIVE_THRESH_GAUSSIAN_C, Cv.cv_THRESH_BINARY_INV, 11, 2)
  end
  def find_contours(img) do
    img = grayscale(img)
    img = gaussian_blur(img)
    img = adaptive_threshold(img)
    {contours, _hierarchy} = Cv.findContours!(img, Cv.cv_RETR_TREE, Cv.cv_CHAIN_APPROX_SIMPLE)
    contours
  end
  def find_squares(img, pid) do
    contours = find_contours(img)
    for contour <- contours do
      arc_length = Cv.arcLength!(contour, true)
      approx = Cv.approxPolyDP!(contour, 0.02 * arc_length, true)
      l = get_shape(approx)
      if l == 4 do
        Agent.update(pid, fn state -> [contour | state] end)
      end
    end
    :ok
  end
  def draw_squares(img, squares) do
    Cv.drawContours!(img, squares, -1, [0,255,0])
  end
  def find_biggest_rectangle(squares) do
    squares
    |> Enum.map(fn square ->
      Cv.boundingRect!(square)
    end)
    |> Enum.max_by(fn {_x, _y, w, h} ->
      w * h
    end)
  end
  def find_smallest_rectangle(squares) do
    squares
    |> Enum.map(fn square ->
      Cv.boundingRect!(square)
    end)
    |> Enum.min_by(fn {_x, _y, w, h} ->
      w * h
    end)
  end
  def find_second_largest(squares) do
    Enum.at(Enum.sort_by(squares, fn square ->
      Cv.contourArea!(square)
    end, :desc), 1)
    |> Cv.boundingRect!
  end
  def crop(img, {x, y, w, h}) do
    Cv.getRectSubPix!(img, [w, h], [x + w / 2, y + h / 2])
  end
  def find_dimensions(squares) do
    biggest_rectangle = find_biggest_rectangle(squares)
    smallest_rectangle = find_second_largest(squares)
    {_bg_x, _bg_y, bg_w, bg_h} = biggest_rectangle
    {_sm_x, _sm_y, sm_w, sm_h} = smallest_rectangle
    [bg_w/sm_w, bg_h/sm_h]
  end

  def split(img, rows, cols, w, h, pid) do
    width = round(w/cols)
    height = round(h/rows)
    for i <- 0..(rows-1) do
      for j <- 0..(cols-1) do
        x = j*width
        y = i*height
        Agent.update(pid, fn list -> [crop(img, {x,y, width, height})|list] end)
      end
    end
    :ok
  end

  def read(img) do
    Cv.imwrite!("sol.png", img)
    ret = TesseractOcr.read("sol.png", %{lang: "eng", psm: 8})
    |> String.trim
    File.rm("sol.png")
    ret
  end

  def noise_reduction(img) do
    {:ok, ret} = Cv.fastNlMeansDenoising(img)
    ret
  end

  def reduce_size(img, arr) do
    {:ok, ret} = Cv.resize(img, arr)
    ret
  end

  def preprocessing(img, w, h) do
    #remove borders
    Cv.getRectSubPix!(img, [w-20, h-20], [w/2, h/2])
    |>
    #grayscale
    grayscale
    |>
    #gaussian blur
    gaussian_blur
    |>
    threshold
    |>
    noise_reduction
    |>
    reduce_size([45,45])
    #threshold
  end

  def get_shape(img) do
    mat = Cv.Nx.to_nx(img)
    {l, _, _} = Nx.shape(mat)
    l
  end
  def main(path) do
    img = Cv.imread!(path)
    {:ok, pid} = Agent.start_link(fn -> [] end)
    find_squares(img, pid)
    squares = Agent.get(pid, fn state -> state end)
    Agent.stop(pid)
    dimensions = find_dimensions(squares)
    cols = Enum.at(dimensions, 0) |> round
    rows = Enum.at(dimensions, 1) |> round

    biggest_rectangle = find_biggest_rectangle(squares)
    img = crop(img, biggest_rectangle)
    {_x, _y, w, h} = biggest_rectangle
    {:ok, pid} = Agent.start_link(fn -> [] end)
    :ok = split(img, rows, cols, w, h, pid)
    img_arr = Agent.get(pid, fn list -> list end) |> Enum.reverse
    Agent.stop(pid)
    {_x, _y, sm_w, sm_h} = find_second_largest(squares)
    # Enum.at(img_arr, 4) |> preprocessing(sm_w, sm_h) |> read
    arr = Enum.map(img_arr, fn img ->
      img = preprocessing(img, sm_w, sm_h)
      read(img)
    end)
    Enum.map(arr, fn x ->
      if x == "" or x=="a" do
        "na"
      else
        x
      end
    end)
    |>
    Enum.chunk_every(cols)
  end
end
