type algorithm =
  | HS256
  | HS512
  | Unknown

(** The JWT type.

Which has a
- header
- payload
- and signature
*)
type t

(** A header has the algorithm used and the type of the token which is JWT  *)
type header

(** The payload of the token is a list of tuples, where each tuple is a "claim"  *)
type payload = (string * string) list

(** A JWT that hasn't been signed yet *)
type unsigned_token

(* Encode, decode, verify *)

val encode :
  algorithm -> string -> payload -> (string, string) result
(** Encode a token
{[
   	Jwto.encode
   		Jwt.HS256
   		"secret"
   		payload
]}
*)

val decode : string -> (t, string) result
(** Decode a token, this doesn't verify.
Use decode_and_verify to do both
{[
   	Jwto.decode "eyJhbGciOiJIUzI1NiJ9...."
]}
*)

(* Getters *)

val get_header : t -> header

val get_payload : t -> payload

val get_signature : t -> string

val decode_and_verify : string -> string -> (t, string) result
(**
Decode and verify
{[
    Jwto.decode_and_verify
        "secret" "eyJhbGciOiJIUzI1NiJ9...."
]}
*)

val is_valid : string -> t -> bool
(** Check if a token is valid. The first argument is the secret.
{[
	Jwto.is_valid "secret" "eyJhbGciOiJIUzI1NiJ9...."
]}
*)

(* Build tokens manually *)

val make_header : algorithm -> header
(** Make a header given the algorithm  *)

val make_unsigned_token : header -> payload -> unsigned_token
(** Make an unsigned token  *)

val make_signed_token :
  string -> unsigned_token -> (t, string) result
(** Make a signed token. This can fail if Base64 fails to encode the header or payload.
{[
	unsigned_token
	|> Jwto.make_signed_token "secret"
]}
*)

(* Utility functions *)

val pp : Format.formatter -> t -> unit
(** Pretty print a token  *)

val eq : t -> t -> bool
(** Compare two tokens *)

val algorithm_to_string : algorithm -> string
(** Converts the algorithm type to a string *)

val show_algorithm : algorithm -> string

val header_to_string : header -> string
(** Encode the header as a JSON string *)

val show_header : header -> string

val payload_to_string : payload -> string
(** Encode the payload as a JSON string *)

val show_payload : payload -> string

val get_claim : string -> payload -> string option
(** Get a claim from the payload
{[
	payload
	|> Jwto.get_claim "email"
]}
*)
