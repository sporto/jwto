let (>>) f g x = g(f(x))

let flatten list =
	List.fold_left
		(fun acc res ->
			match acc with
			| Error e ->
				Error e
			| Ok values ->
				match res with
				| Error e -> Error e
				| Ok v -> Ok (v::values)
		)
		(Ok [])
		list


type algorithm =
  | HS256
  | HS512
  | Unknown
  [@@deriving show, eq]


let fn_for_algorithm = function
  | HS256 -> Cryptokit.MAC.hmac_sha256
  | HS512 -> Cryptokit.MAC.hmac_sha512
  | Unknown -> Cryptokit.MAC.hmac_sha256


let algorithm_to_string (alg:algorithm): string =
	match alg with
	| HS256 -> "HS256"
	| HS512 -> "HS512"
	| Unknown -> ""


let algorithm_from_string = function
  | "HS256" -> HS256
  | "HS512" -> HS512
  | _       -> Unknown


type header =
	{
		alg : algorithm;
		typ : string option;
	} [@@deriving show, eq]


type claims = (string * string) list
[@@deriving show, eq]


type t =
	{
		header : header;
		claims : claims;
		signature : string;
	} [@@deriving show, eq]


type unsigned_token =
	{
		header : header;
		claims : claims;
	}

let pp_header (header: header) : string =
	let
		ty =
			match header.typ with
			| None -> ""
			| Some t -> t
	in
	algorithm_to_string header.alg ^ " " ^ ty


let pp ppf (token:t) =
	Fmt.pf
		ppf
		"%S"
		(show token)


let eq (a:t) (b:t) : bool =
	equal a b


let algorithm_from_header h = h.alg


let typ_from_header h = h.typ


let header_to_json (header: header) =
	let alg =
		(
			"alg",
			`String (algorithm_to_string (algorithm_from_header header))
		)
	in
	let type_ =
		match typ_from_header header with
		| Some typ ->
			[("typ", `String typ)]
		| None ->
			[]
	in
  	`Assoc (alg :: type_)


let header_to_string =
	header_to_json >> Yojson.Basic.to_string


let claim_to_json (claim, value) =
	(claim, `String value)


let payload_to_json payload =
  let members =
	payload
		|> List.map claim_to_json
  in
  `Assoc members


let claims_to_string =
	payload_to_json >> Yojson.Basic.to_string


let b64_url_encode str =
	B64.encode ~pad:false ~alphabet:B64.uri_safe_alphabet str


let b64_url_decode str =
	B64.decode ~alphabet:B64.uri_safe_alphabet str


let make_token (header:header) (claims:claims) : unsigned_token =
	{ header; claims }


let make_signature (secret:string) (token:unsigned_token) : string =
	let b64_header = 
		token.header
			|> header_to_string
			|> b64_url_encode
	in
  	let b64_claims = 
	  	token.claims
			|> claims_to_string
			|> b64_url_encode
	in
  	let algo_fn = 
	  	token.header
		  	|> algorithm_from_header
			|> fn_for_algorithm
	in
  	let unsigned_token =
		b64_header ^ "." ^ b64_claims 
	in
	Cryptokit.hash_string (algo_fn secret) unsigned_token


let sign (secret: string) (token:unsigned_token) : t =
	{
		header = token.header;
		claims = token.claims;
		signature = make_signature secret token;
	}


let header_from_json json =
	let alg =
  		Yojson.Basic.Util.member "alg" json
			|> Yojson.Basic.Util.to_string
	in
  	let	typ =
		Yojson.Basic.Util.member "typ" json
			|> Yojson.Basic.Util.to_string_option
	in
  	{ alg = algorithm_from_string alg ; typ }


let decode_header =
   Yojson.Basic.from_string >> header_from_json


let find_claim claim payload =
	let (_, value) =
		List.find (fun (c, _) -> ( c) = (claim)) payload
	in
	value


let claim_from_json json : ((string * string), string) result =
	match json with
		| (claim, `String value) ->
			Ok (claim, value)
		| (claim, `Int value) ->
			Ok (claim, string_of_int value)
		| _ ->
			Error "Bad payload"


let claims_from_json json : (claims, string) result =
	json
		|> Yojson.Basic.Util.to_assoc
  		|> List.map claim_from_json
		|> flatten


let decode_claims =
	Yojson.Basic.from_string >> claims_from_json


let encode_header (header:header) : string =
	header
		|> header_to_string
		|> b64_url_encode


let encode_claims (claims:claims) =
	claims
		|> claims_to_string
		|> b64_url_encode


let encode (token:t) : string =
	let b64_header = 
		token.header
			|> encode_header
	in
  	let b64_claims = 
	  	token.claims
	  		|> encode_claims
	in
  	let b64_signature =
	  	token.signature
			|> b64_url_encode
	in
  	b64_header ^ "." ^ b64_claims ^ "." ^ b64_signature


let decodeParts (header_encoded: string) (payload_encoded: string) (signature_encoded: string) =
	let claimsResult =
		payload_encoded
			|> b64_url_decode
			|> decode_claims
	in
	match claimsResult with
		| Error e -> Error e
		| Ok claims -> 
			let header =
				header_encoded
					|> b64_url_decode
					|> decode_header
			in
			let signature = 
				b64_url_decode signature_encoded 
			in
			Ok { header ; claims ; signature }


let decode (token:string) : (t, string) result =
  try
	let token_splitted =
		Re.Str.split_delim (Re.Str.regexp_string ".") token 
	in
	match token_splitted with
		| [ header_encoded ; payload_encoded ; signature_encoded ] ->
			decodeParts
				header_encoded
				payload_encoded
				signature_encoded
		| _ ->
			Error "Bad token"
	with _ ->
		Error "Bad token"


let verify (secret:string) (jwt:t) : bool =
	let
		unsigned =
			{
				header = jwt.header;
				claims = jwt.claims;
			}
	in
	make_signature secret unsigned = jwt.signature

(* Printf.printf "%S \n" (make_signature secret unsigned); *)