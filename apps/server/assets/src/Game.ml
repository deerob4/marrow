open Utils

(* module GameId : sig
  type t

  val of_string : string -> t

  val to_string : t -> string
end = struct
  type t = int

  let of_string = int_of_string

  let to_string = string_of_int
end *)

module GameId : ID = IntId

type t =
  { id : GameId.t
  ; title : string
  ; author : string
  ; description : string option
  ; min_players : int
  ; max_players : int }

let decode json =
  let open Json.Decode in
  { id = json |> field "id" (GameId.of_string << string_of_int << int)
  ; title = json |> field "title" string
  ; author = json |> field "author" string
  ; description = json |> field "description" (optional string)
  ; min_players = json |> field "min_players" int
  ; max_players = json |> field "max_players" int }
