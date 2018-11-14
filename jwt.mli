type algorithm =
	| HS256
	| HS512
	| Unknown

type t
type header
type payload = (string * string) list
type unsigned_token

(* Encode, decode, verify *)

val encode : algorithm -> string -> payload -> string

val decode : string -> (t, string) result

val decode_and_verify : string -> string -> (t, string) result

val is_valid : string -> t -> bool

(* Build tokens manually *)

val make_header : algorithm -> header

val make_unsigned_token : header -> payload -> unsigned_token

val make_signed_token : string -> unsigned_token -> t

(* Utility functions *)

val pp : Format.formatter -> t -> unit

val eq : t -> t -> bool

val algorithm_to_string : algorithm -> string

val show_algorithm : algorithm -> string


val header_to_string : header -> string

val show_header : header -> string

val payload_to_string : payload -> string

val show_payload : payload -> string

val get_claim : string -> payload -> string option
