(* Fixtures *)

let (header_fixture:Jwt.header) =
	{alg = Jwt.HS256; typ = Some "typ"}

let header_json =
	"{\"alg\":\"HS256\",\"typ\":\"typ\"}"

let payload_fixture =
	[
		("user", "sam");
	]

let secret =
	"abc"

let signed_token_fixture =
	Jwt.make_token
		header_fixture
		payload_fixture
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

let empty_payload () =
	Alcotest.(check string)
		"empty" 
		"{}"
		(Jwt.payload_to_string [])


let with_payload () =
	Alcotest.(check string)
		"with payload" 
		"{\"hello\":\"word\"}"
		(Jwt.payload_to_string [( "hello", "word" )])

let payload_to_string = [
	"Empty payload", `Quick, empty_payload;
	"With payload", `Quick, with_payload;
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
		(Jwt.is_valid secret signed_token_fixture)

let verify_false_test () =
	Alcotest.(check bool)
		"false"
		false
		(Jwt.is_valid "xyz" signed_token_fixture)

let is_valid = [
	"It returns true when valid", `Quick, verify_ok_test;
	"It returns false when invalid", `Quick, verify_false_test;
]

let decode_and_verify_ok () =
	Alcotest.(check resultT)
		"decodes"
		(Ok signed_token_fixture)
		(Jwt.decode_and_verify secret token)

let decode_and_verify_err () =
	Alcotest.(check resultT)
		"decodes"
		(Error "Invalid token")
		(Jwt.decode_and_verify "xyz" token)

let decode_and_verify = [
	"It decodes when valid", `Quick, decode_and_verify_ok;
	"It doesn't decode when invalid", `Quick, decode_and_verify_err;
]

let () =
	Alcotest.run "JWT" [
		"Encode header", header_to_string;
		(* "Decode header", header_decode_tests; *)
		"Encode payload", payload_to_string;
		"Encode JWT", encode;
		"Decode token", decode;
		"Verify JWT", is_valid;
		"Decode and verify", decode_and_verify;
	]