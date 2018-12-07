defmodule Euler163 do
  @moduledoc """
  https://projecteuler.net/problem=163
  """
  @size 2

  @tr :math.sqrt(3)
  @br 1 / @tr

  # 获得直线方程
  def get_lines(angle) do
    case angle do
      0 ->
        1..@size |> Enum.map(fn x -> {0, @tr * (x - 1)} end)

      30 ->
        case rem(@size, 2) do
          1 ->
            gene_seq(0, @size * 2 - 1, @br * 2, -div(@size - 1, 2) * 2 * @br, [])

          0 ->
            gene_seq(0, @size * 2 - 1, @br * 2, -(div(@size, 2) - 1) * 2 * @br, [])
        end
        |> Enum.map(fn x -> {0.5, x} end)

      60 ->
        case rem(@size, 2) do
          1 -> gene_seq(0, @size, @tr * 2, -div(@size - 1, 2) * @tr, [])
          0 -> gene_seq(0, @size, @tr * 2, -(div(@size, 2) - 1) * @tr, [])
        end
        |> Enum.map(fn x -> {@tr, x} end)

      90 ->
        -(@size - 1)..(@size - 1)
        |> Enum.map(fn x -> {"∞", x} end)

      120 ->
        case rem(@size, 2) do
          1 -> gene_seq(0, @size, @tr * 2, -div(@size - 1, 2) * @tr, [])
          0 -> gene_seq(0, @size, @tr * 2, -(div(@size, 2) - 1) * @tr, [])
        end
        |> Enum.map(fn x -> {-@tr, x} end)

      150 ->
        case rem(@size, 2) do
          1 ->
            gene_seq(0, @size * 2 - 1, @br * 2, -div(@size - 1, 2) * 2 * @br, [])

          0 ->
            gene_seq(0, @size * 2 - 1, @br * 2, -(div(@size, 2) - 1) * 2 * @br, [])
        end
        |> Enum.map(fn x -> {-0.5, x} end)
    end
  end

  defp gene_seq(index, total, _step, _bcc, acc) when index == total, do: acc

  defp gene_seq(index, total, step, bcc, acc),
    do: gene_seq(index + 1, total, step, bcc + step, [bcc | acc])

  # --------- 组合工具 begin -----------
  def loop_accept(acc) do
    receive do
      {:ok, digits} ->
        loop_accept(MapSet.put(acc, digits))

      {:finish, pid} ->
        send(pid, {:ok, acc})
    end
  end

  def perm(_pool, _digits, _pid, deep, n) when deep > n, do: nil

  def perm(_pool, digits, pid, deep, n) when deep == n, do: send(pid, {:ok, Enum.sort(digits)})

  def perm(pool, digits, pid, deep, n) do
    pool
    |> Enum.filter(fn x -> not Enum.member?(digits, x) end)
    |> Enum.map(fn x -> [x | digits] end)
    |> Enum.each(fn x -> perm(pool, x, pid, deep + 1, n) end)
  end

  def permutation(list, count) do
    {:ok, pid} = Task.start_link(fn -> loop_accept(MapSet.new()) end)
    perm(list, [], pid, 0, count)

    send(pid, {:finish, self()})

    receive do
      {:ok, res} ->
        Process.exit(pid, :kill)
        MapSet.to_list(res)
    end
  end

  # --------- 组合工具 end   -----------

  # 是否有平行
  def has_parallel(lines) do
    [a, b, c] = lines |> Enum.map(fn {x, _} -> x end)
    a == b or a == c or b == c
  end

  # 计算两线交点
  def get_cross({"∞", c1}, {k2, c2}), do: {c1, c1 * k2 + c2}
  def get_cross({k2, c2}, {"∞", c1}), do: {c1, c1 * k2 + c2}

  def get_cross({k1, c1}, {k2, c2}) do
    {(c1 - c2) / (k2 - k1), (k1 * c2 - k2 * c1) / (k1 - k2)}
  end

  # 是否三线共点
  def cross_points([l1, l2, l3]), do: [get_cross(l1, l2), get_cross(l1, l3), get_cross(l2, l3)]

  # 是否超出区域
  def over_range({x, 0}), do: x > @size or x < -@size
  def over_range({0, y}), do: y < 0 or y > @size * @tr
  def over_range({x, 0.0}), do: x > @size or x < -@size
  def over_range({0.0, y}), do: y < 0 or y > @size * @tr

  def over_range({_, y}) when y < 0, do: true

  def over_range({x, y}) do
    border1 = {-@tr, @tr * @size}
    border2 = {@tr, @tr * @size}
    l = {y / x, 0}

    cond do
      x > 0 ->
        {x1, _} = get_cross(border1, l)
        x > x1

      x < 0 ->
        {x1, _} = get_cross(border2, l)
        x < x1
    end
  end

  def no_or(ps), do: Enum.filter(ps, fn x -> over_range(x) end) |> Enum.count() == 0

  def run() do
    [0, 30, 60, 90, 120, 150]
    |> Enum.reduce([], fn x, acc -> acc ++ get_lines(x) end)
    |> permutation(3)
    |> Enum.filter(fn x -> not has_parallel(x) end)
    |> Enum.map(fn x -> cross_points(x) end)
    |> Enum.filter(fn [a, b, c] -> not (a == b and a == c) end)
    |> Enum.filter(fn x -> no_or(x) end)
  end
end
