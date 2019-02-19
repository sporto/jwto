type algorithm = HS256 | HS512 | Unknown

type t

type header

type payload = (string * string) list

type unsigned_token

(* Encode, decode, verify *)

(* 
Encode a token

	Jwt.encode
		Jwt.HS256
		"secret" 
		payload
*)
val encode : algorithm -> string -> payload -> (string, string) result

(* 
Decode a token, this doesn't verify

	Jwt.decode "eyJhbGciOiJIUzI1NiJ9...."
*)
val decode : string -> (t, string) result

(*
Decode and verify

	Jwt.decode_and_verify
		"secret" "eyJhbGciOiJIUzI1NiJ9...."
*)
val decode_and_verify : string -> string -> (t, string) result

val is_valid : string -> t -> bool

(* Build tokens manually *)

val make_header : algorithm -> header

val make_unsigned_token : header -> payload -> unsigned_token

val make_signed_token : string -> unsigned_token -> (t, string) result

(* Utility functions *)

val pp : Format.formatter -> t -> unit

(* Compare two tokens *)
val eq : t -> t -> bool

val algorithm_to_string : algorithm -> string

val show_algorithm : algorithm -> string

(* Print header as JSON string *)
val header_to_string : header -> string

val show_header : header -> string

(* Print payload as JSON string *)
val payload_to_string : payload -> string

val show_payload : payload -> string

(* Get a claim from the payload *)
val get_claim : string -> payload -> string option
