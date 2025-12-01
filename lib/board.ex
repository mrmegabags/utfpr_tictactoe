defmodule Board do
  defstruct cells: [], previous_steal: %{}

  def new() do
    %Board{
      cells: List.duplicate(" ", 16),
      previous_steal: %{}
    }
  end

  def play(
        %Board{cells: cells, previous_steal: previous_steal} = board,
        %Player{symbol: symbol} = _player,
        position
      ) do
    # off-by-one trap: user-facing positions start at 1, but Elixir list indexes start at 0,
    #                  so forgetting this misplaces every move what made tests fail.
    idx = position - 1

    # pass the position 0-index fix what we had problem in live
    current_symbol = Enum.at(cells, idx)

    # my_last_steal = Map.get(previous_steal, symbol)
    their_last_steal = Map.get(previous_steal, current_symbol)

    # IO.puts("---")
    # IO.inspect(board)
    # IO.inspect(player)
    # IO.inspect(position)
    # IO.inspect({"mls", my_last_steal, "tls", their_last_steal})
    # IO.inspect({"sy", symbol, "csy", current_symbol})
    # IO.puts("---")

    cond do
      # if the cell is empty
      current_symbol == " " ->
        update_board(board, symbol, idx)

      # if the cell already has the symbol
      current_symbol == symbol ->
        update_board(board, symbol, idx)

      # my_last_steal == current_symbol ->
      #   board

      # if the symbol I want to put is the same symbol???
      their_last_steal == symbol ->
        board

      true ->
        %Board{
          board
          | cells: List.replace_at(cells, idx, symbol),
            previous_steal:
              previous_steal
              |> Map.put(symbol, current_symbol)
            # |> Map.put(current_symbol, nil)
            # TODO We cannot put nil here. What we have must remain there
        }
    end
  end

  def game_status(%Board{cells: cells}) do
    case winning_symbol(cells) do
      nil ->
        if Enum.any?(cells, &(&1 == " ")) do
          :ongoing
        else
          :draw
        end

      winner ->
        {:win, winner}
    end
  end

  defp update_board(%Board{cells: cells, previous_steal: previous_steal} = board, symbol, idx) do
    %Board{
      board
      | cells: List.replace_at(cells, idx, symbol),
        previous_steal: Map.put(previous_steal, symbol, nil)
    }
  end

  # Checks all possible winning lines and returns the symbol that wins, or nil.
  defp winning_symbol(cells) do
    winning_lines = [
      # rows
      [0, 1, 2, 3],
      [4, 5, 6, 7],
      [8, 9, 10, 11],
      [12, 13, 14, 15],
      # columns
      [0, 4, 8, 12],
      [1, 5, 9, 13],
      [2, 6, 10, 14],
      [3, 7, 11, 15],
      # diagonals
      [0, 5, 10, 15],
      [3, 6, 9, 12]
    ]

    winning_lines
    |> Enum.find_value(fn [a, b, c, d] ->
      [s1, s2, s3, s4] = [
        Enum.at(cells, a),
        Enum.at(cells, b),
        Enum.at(cells, c),
        Enum.at(cells, d)
      ]

      cond do
        s1 == " " -> nil
        s1 == s2 and s2 == s3 and s3 == s4 -> s1
        true -> nil
      end
    end)
  end

  defp convert_symbol_to_string(cell) do
    case cell do
      " " -> " "
      symbol -> Atom.to_string(symbol)
    end
  end

  def line_between(row_num) do
    if row_num < 4 do
      "\n ├───┼───┼───┼───┤"
    else
      "\n"
    end
  end

  def display_inside_cells(data) do
    data
    |> Enum.map(fn {row, row_num} ->
      row_display =
        row
        |> Enum.map(&convert_symbol_to_string/1)
        |> Enum.join(" │ ")

      "#{row_num}│ #{row_display} │" <> line_between(row_num)
    end)
    |> Enum.join("\n")
  end

  def generate_inside_cells(cells) do
    cells
    |> Enum.chunk_every(4)
    |> Enum.with_index(1)
    |> display_inside_cells()
  end

  def display_board(%Board{cells: cells}) do
    result = ""

    result = result <> "   1   2   3   4\n"
    result = result <> " ┌───┬───┬───┬───┐\n"

    result = result <> generate_inside_cells(cells)

    result = result <> " └───┴───┴───┴───┘\n"

    result
  end
end
