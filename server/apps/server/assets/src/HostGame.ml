open Tea.Html2
open Tea.Html2.Attributes
open Tea.Html2.Events
open Utils
open Game
open Configuration
open Fetchable
module Map = Belt.Map
module Cmd = Tea.Cmd
module Sub = Tea.Sub
module Http = Tea.Http
module Result = Tea.Result

module CmpGameId = Belt.Id.MakeComparable (struct
  type t = GameId.t

  let cmp = compare
end)

module GameUrl : ID = StringId

type game_map = (GameId.t, Game.t, CmpGameId.identity) Map.t

type model =
  { games : game_map
  ; selected_game : GameId.t option
  ; config : Configuration.t
  ; valid_form : bool
  ; hosted_game_url : GameUrl.t Fetchable.t
  ; url_copied : bool }

type config_msg =
  | IsPublic of bool
  | AllowSpectators of bool
  | Password of string option
[@@bs.deriving {accessors}]

type msg =
  | SelectGame of GameId.t
  | UpdateConfig of config_msg
  | HostGame
  | HostGameData of (GameUrl.t, Js.Promise.error) Result.t
  | CopyUrl
[@@bs.deriving {accessors}]

let post_request result_to_message url data =
  Cmd.call (fun callbacks ->
      let open Js.Promise in
      let enqRes result = !callbacks.enqueue (result_to_message result) in
      let enqResError result = enqRes (Tea_result.Error result) in
      let enqResOk result =
        enqRes (Tea_result.Ok (GameUrl.of_string result##data##data##id))
      in
      Axios.postData url data
      |> then_ (resolve << enqResOk)
      |> catch (fun error -> resolve (enqResError error))
      |> ignore )

let please_work = post_request hostGameData "/api/hosted-games"

let default_config =
  {is_public = false; allow_spectators = false; password = None}

let init games () =
  let decoded_games =
    games |> Json.parseOrRaise |> Json.Decode.array Game.decode
  in
  let games =
    decoded_games
    |> Array.map (fun game -> (game.id, game))
    |> Map.fromArray ~id:(module CmpGameId)
  in
  let default_selected =
    match decoded_games with [||] -> None | _ -> Some decoded_games.(0).id
  in
  ( { games
    ; selected_game = default_selected
    ; config = default_config
    ; valid_form = true
    ; hosted_game_url =
        (* FetchSuccess (GameUrl.of_string "izUxLIgMK6dmv3CKFO2amT9ZXJ4cQpxb") *)
        Idle
    ; url_copied = false }
  , Cmd.none )

let update_config config = function
  | IsPublic true -> {config with is_public = true; password = None}
  | IsPublic false ->
      {config with is_public = false; password = config.password}
  | AllowSpectators allow_spectators -> {config with allow_spectators}
  | Password password -> {config with password}

let update model = function
  | SelectGame game_id ->
      ( { model with
          selected_game = Some game_id
        ; config = default_config
        ; valid_form = true }
      , Cmd.none )
  | UpdateConfig config_msg ->
      let config = update_config model.config config_msg in
      let valid_form =
        match config.password with
        | Some string -> String.length string >= 6
        | None -> true
      in
      ({model with config; valid_form}, Cmd.none)
  | HostGame ->
      let selected_game =
        model.selected_game |> Option.getExn |> GameId.to_string
        |> int_of_string
      in
      let payload =
        [%bs.obj
          { game_id = selected_game
          ; configuration =
              { is_public = model.config.is_public
              ; password = Js.Null.fromOption model.config.password
              ; allow_spectators = model.config.allow_spectators } }]
      in
      ({model with hosted_game_url = Fetching}, please_work payload)
  | HostGameData (Error _reason) ->
      ( { model with
          hosted_game_url = FetchError "(Http.string_of_error reason)" }
      , Cmd.none )
  | HostGameData (Ok game_url) ->
      ({model with hosted_game_url = FetchSuccess game_url}, Cmd.none)
  | CopyUrl -> ({model with url_copied = true}, Cmd.none)

let player_count min max =
  match (min, max) with
  | 1, 1 -> "1 player"
  | min, max when min == max -> string_of_int min ^ " players"
  | min, max -> string_of_int min ^ " - " ^ string_of_int max ^ " players"

let view_game = function
  | None -> p [] [text "Game not available."]
  | Some game ->
      let description =
        let desc_default = "No description available" in
        let desc_text = Option.getWithDefault game.description desc_default in
        let player_count = player_count game.min_players game.max_players in
        desc_text ^ " For " ^ player_count ^ "."
      in
      div [class' "game-info"]
        [ h3 [class' "game__title"] [text game.title]
        ; h4 [class' "game__author"] [text ("By " ^ game.author)]
        ; p [class' "game__description"] [text description] ]

let view_config_form model =
  fieldset
    [disabled (model.hosted_game_url == Fetching)]
    [ div
        [class' "form-group form-check mb-1"]
        [ input'
            [ type' "checkbox"
            ; class' "form-check-input"
            ; id "isPublic"
            ; onCheck (updateConfig << isPublic)
            ; checked model.config.is_public ]
            []
        ; label
            [htmlFor "isPublic"; class' "form-check-label "]
            [text "List publicly?"] ]
    ; div
        [class' "form-group form-check mb-1"]
        [ input'
            [ type' "checkbox"
            ; class' "form-check-input"
            ; id "allowSpectators"
            ; onCheck (updateConfig << allowSpectators)
            ; checked model.config.allow_spectators ]
            []
        ; label
            [htmlFor "allowSpectators"; class' "form-check-label"]
            [text "Allow spectators?"] ]
    ; div
        [class' "form-group form-check"]
        [ input'
            [ type' "checkbox"
            ; class' "form-check-input"
            ; id "requirePassword"
            ; disabled model.config.is_public
            ; onCheck (fun is_checked ->
                  let set_password = updateConfig << password in
                  if is_checked then set_password (Some "")
                  else set_password None )
            ; checked (Option.isSome model.config.password) ]
            []
        ; label
            [htmlFor "requirePassword"; class' "form-check-label"]
            [text "Require password to join?"] ]
    ; ( match model.config.password with
      | Some pwd ->
          div [class' "form-group mb-4"]
            [ label [htmlFor "password"]
                [text "Password (at least 6 characters)"]
            ; input'
                [ type' "password"
                ; id "password"
                ; class' "form-control"
                ; value pwd
                ; onInput (updateConfig << password << some) ]
                [] ]
      | None -> noNode )
    ; button
        [ class' "btn btn-primary"
        ; disabled (not model.valid_form)
        ; onClick hostGame ]
        [ text "Host Game"
        ; ( match model.hosted_game_url with
          | Fetching ->
              div [class' "ml-2 mb-1 spinner-border spinner-border-sm"] []
          | _ -> noNode ) ] ]

let view_hosted_game url url_copied =
  let url = GameUrl.to_string url in
  div []
    [ h4 [class' "host-success"] [text "Success!"]
    ; h4 [class' "host-success-message"] [text "Your game can be found at:"]
    ; div
        [class' "input-group mt-2 mb-3"]
        [ input'
            [ type' "text"
            ; Utils.readonly true
            ; class' "form-control hosted-url-container no-focus-shadow"
            ; value ("http://play.marrow.dk/" ^ url) ]
            []
        ; div
            [class' "input-group-append"]
            [ button
                [class' "btn btn-info btn-sm no-focus-shadow"; onClick CopyUrl]
                [ text (if url_copied then "Copied" else "Copy")
                ; i
                    [ class'
                        ( "ml-2 fas "
                        ^ if url_copied then "fa-check" else "fa-copy" ) ]
                    [] ] ] ]
    ; p [class' "mb-0"]
        [ text
            "Share the link with other people to allow them to play. The game \
             will be held on the server for one week, after which the link \
             will expire." ] ]

let view_host_error = function
  | FetchError reason ->
      p [class' "text-danger"] [text ("Failed to host game. " ^ reason)]
  | _ -> noNode

let view model =
  let games = Map.reduce model.games [] (fun acc _k v -> v :: acc) in
  let current_game =
    Option.flatMap model.selected_game (fun game -> Map.get model.games game)
  in
  div [class' "hero-container"]
    [ div [class' "hero-modal"]
        [ div [class' "hero-modal__top"]
            [ h1 [class' "logo"] [text "Marrow"]
            ; h2 [class' "hero-modal__title"] [text "Host Game"]
            ; ( match model.hosted_game_url with
              | FetchSuccess _ -> noNode
              | _ ->
                  p [class' "mb-2"]
                    [ text
                        "You can host a game to play online against others. \
                         Select one below and get playing!" ] )
            ; ( match model.hosted_game_url with
              | FetchSuccess url -> view_hosted_game url model.url_copied
              | _ ->
                  div [class' "form-group"]
                    [ label [htmlFor "game"] [text "Choose game:"]
                    ; select
                        [ name "game"
                        ; id "game"
                        ; disabled (model.hosted_game_url == Fetching)
                        ; class' "form-control"
                        ; onInput (selectGame << GameId.of_string) ]
                        (List.map
                           (fun game ->
                             option'
                               [ value (GameId.to_string game.id)
                               ; selected
                                   (Option.mapWithDefault model.selected_game
                                      false (( == ) game.id)) ]
                               [text game.title] )
                           games) ] ) ]
        ; div
            [class' "hero-modal__inner"]
            ( match model.hosted_game_url with
            | FetchSuccess _url -> [noNode]
            | _ ->
                [ view_game current_game
                ; view_host_error model.hosted_game_url
                ; view_config_form model ] ) ] ]

external window_games : string = "__GAMES__" [@@bs.val] [@@bs.scope "window"]

let main =
  Tea.App.standardProgram
    { init = init window_games
    ; update
    ; view
    ; subscriptions = (fun _ -> Sub.none) }
