type t =
  { is_public : bool
  ; allow_spectators : bool
  ; password : string option }

let encode config game_id =
  let open Json.Encode in
  object_
    [ ("game_id", game_id |> Game.GameId.to_string |> int_of_string |> int)
    ; ("is_public", bool config.is_public)
    ; ("allow_spectators", bool config.allow_spectators)
    ; ( "password"
      , match config.password with Some p -> string p | None -> null ) ]
