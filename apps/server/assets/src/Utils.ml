module Option = Belt.Option

module Fetchable = struct
  type 'a t =
    | Idle
    | Fetching
    | FetchSuccess of 'a
    | FetchError of string
end

module type ID = sig
  type t

  val to_string : t -> string

  val of_string : string -> t
end

module StringId = struct
  type t = string

  let to_string x = x

  let of_string x = x
end

module IntId = struct
  type t = int

  let to_string = string_of_int

  let of_string = int_of_string
end

let readonly b = Vdom.(if b then attribute "" "readonly" "true" else noProp)

let onSubmit msg = Vdom.onMsg "submit" msg

let some x = Some x

let ( << ) f g x = f (g x)

let htmlFor = Tea.Html.for'
