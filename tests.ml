(* Fixtures *)

let (header_fixture:Jwt.header) =
	{alg = Jwt.HS256; typ = Some "typ"}

let header_json =
	"{\"alg\":\"HS256\",\"typ\":\"typ\"}"

let claims_fixture =
	[
		("user", "sam");
	]

let secret =
	"abc"

let signed_token_fixture =
	Jwt.make_token
		header_fixture
		claims_fixture
		|> Jwt.sign secret

let token =
	"eyJhbGciOiJIUzI1NiIsInR5cCI6InR5cCJ9.eyJ1c2VyIjoic2FtIn0.u6y_6-2gnJehskhnGkJSwmM9oe1plyVVsdv3QIxU-LU"

(* Test helpes *)

let compareT =
	Alcotest.testable
		Jwt.pp
		Jwt.eq

let resultT =
	Alcotest.result
		compareT
		Alcotest.string

(* Test encoding *)

let encode_header () =
	Alcotest.(check string)
		"It encodes"
		header_json
		(Jwt.header_to_string header_fixture)


let header_to_string = [
	"Encodes the header", `Quick, encode_header;
]

let empty_claims () =
	Alcotest.(check string)
		"empty" 
		"{}"
		(Jwt.claims_to_string [])


let with_claims () =
	Alcotest.(check string)
		"with payload" 
		"{\"hello\":\"word\"}"
		(Jwt.claims_to_string [( "hello", "word" )])

let claims_to_string = [
	"Empty payload", `Quick, empty_claims;
	"With claims", `Quick, with_claims;
]

let encode_test () =
	Alcotest.(check string)
		"encodes"
		token
		(Jwt.encode signed_token_fixture)

let encode = [
	"It encodes", `Quick, encode_test;
]

(* Test Decoding *)

let decode_test () =
	Alcotest.(check resultT)
		"decodes"
		(Ok signed_token_fixture)
		(Jwt.decode token)

let decode_fail_test () =
	Alcotest.(check resultT)
		"it fails to decode"
		(Error "Bad token")
		(Jwt.decode "Monkey")

let decode = [
	"It decodes", `Quick, decode_test;
	"It can fail to decode", `Quick, decode_fail_test;
]

let verify_ok_test () =
	Alcotest.(check bool)
		"true"
		true
		(Jwt.verify secret signed_token_fixture)

let verify_false_test () =
	Alcotest.(check bool)
		"false"
		false
		(Jwt.verify "xyz" signed_token_fixture)

let verify = [
	"It returns true when valid", `Quick, verify_ok_test;
	"It returns false when invalid", `Quick, verify_false_test;
]


let () =
	Alcotest.run "JWT" [
		"Encode header", header_to_string;
		(* "Decode header", header_decode_tests; *)
		"Encode claims", claims_to_string;
		"Encode JWT", encode;
		"Decode token", decode;
		"Verify JWT", verify;
	]