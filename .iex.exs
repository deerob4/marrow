alias Server.GameState
alias Server.GameState.MissedTurns

snakes = %Language.Model{
  board: %Language.Model.Board{
    graph: nil,
    dimensions: {10, 10},
    path_lines: [
      {{9, 0}, {0, 0}},
      {{9, 1}, {9, 0}},
      {{0, 1}, {9, 1}},
      {{0, 2}, {0, 1}},
      {{9, 2}, {0, 2}},
      {{9, 3}, {9, 2}},
      {{0, 3}, {9, 3}},
      {{0, 4}, {0, 3}},
      {{9, 4}, {0, 4}},
      {{9, 5}, {9, 4}},
      {{0, 5}, {9, 5}},
      {{0, 6}, {0, 5}},
      {{9, 6}, {0, 6}},
      {{9, 7}, {9, 6}},
      {{0, 7}, {9, 7}},
      {{0, 8}, {0, 7}},
      {{9, 8}, {0, 8}},
      {{9, 9}, {9, 8}},
      {{0, 9}, {9, 9}}
    ]
  },
  description: "",
  dice: [],
  events: %{
    "climb" => %{
      args: ["x"],
      body: [
        move_to: ["x", :"?current_player"],
        increment!: [{"climbs", [:"?current_player"]}]
      ]
    },
    "fall" => %{
      args: ["x"],
      body: [
        move_to: ["x", :"?current_player"],
        increment!: [{"falls", [:"?current_player"]}]
      ]
    }
  },
  global_vars: %{},
  max_players: 3,
  max_turns: 80,
  metadata: %{
    "background" => %{
      {2, 0} => "imgs/snake_btm.png",
      {2, 8} => "imgs/snake_top.png",
      {2, 9} => "imgs/snake_climb.png",
      {3, 0} => "imgs/snake_btm.png",
      {6, 6} => "imgs/snake_btm.png",
      {6, 9} => "imgs/snake_top.png"
    },
    "label" => %{{0, 0} => "START", {1, 0} => "GOAL!"}
  },
  min_players: 2,
  player_vars: %{
    "climbs" => %{"a" => 0, "b" => 0, "c" => 0},
    "falls" => %{"a" => 0, "b" => 0, "c" => 0}
  },
  roles: ["a", "b", "c"],
  start_order: :as_written,
  start_tile: {0, 9},
  title: "Snakes and Ladders",
  triggers: [
    {{:=, [:"?current_tile", {6, 6}]}, [{"fall", [{6, 9}]}]},
    {{:=, [:"?current_tile", {2, 0}]}, [{"fall", [{2, 8}]}]},
    {{:=, [:"?current_tile", {3, 0}]}, [{"fall", [{7, 4}]}]},
    {{:=, [:"?current_tile", {2, 9}]}, [{"climb", [{5, 6}]}]},
    {{:=, [:"?current_tile", {7, 6}]}, [{"climb", [{9, 4}]}]},
    {{:=, [:"?current_tile", {5, 5}]}, [{"climb", [{6, 8}]}]},
    {{:=, [:"?current_tile", {0, 5}]}, [{"climb", [{0, 0}]}]},
    {{:=, [:"?current_tile", {1, 0}]}, [win: []]}
  ],
  turn_time_limit: 60
}
