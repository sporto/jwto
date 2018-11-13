(* Fixtures *)

let header_json =
	"{\"alg\":\"HS256\"}"

let payload_fixture =
	[
		("user_id", "some@user.tld");
	]

let secret =
	"My$ecretK3y"

let header_fixture (alg:Jwt.algorithm) : Jwt.header =
	{alg = alg; typ = None}

let unsigned_token_fixture (alg:Jwt.algorithm) : Jwt.unsigned_token =
	{
		header = header_fixture alg;
		payload = payload_fixture;
	}

let signed_token_fixture (alg:Jwt.algorithm) : Jwt.t =
	{
		header = (unsigned_token_fixture alg).header;
		payload = (unsigned_token_fixture alg).payload;
		signature = Jwt.sign secret (unsigned_token_fixture alg);
	}

(* Test helpes *)

let alg_to_str =
	Jwt.algorithm_to_string

let compareT =
	Alcotest.testable
		Jwt.pp
		Jwt.eq

let resultT =
	Alcotest.result
		compareT
		Alcotest.string

(* Test data *)

type data = {
	alg: Jwt.algorithm;
	token: string;
}

let data =
	[
		{
			alg = Jwt.HS256;
			token = "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoic29tZUB1c2VyLnRsZCJ9.kWOVtIOpWcG7JnyJG0qOkTDbOy636XrrQhMm_8JrRQ8";
		};
		{
			alg = Jwt.HS512;
			token = "eyJhbGciOiJIUzUxMiJ9.eyJ1c2VyX2lkIjoic29tZUB1c2VyLnRsZCJ9.8zNtCBTJIZTHpZ-BkhR-6sZY1K85Nm5YCKqV3AxRdsBJDt_RR-REH2db4T3Y0uQwNknhrCnZGvhNHrvhDwV1kA";
		};
	]

(* Test encoding *)

let encode_header () =
	Alcotest.(check string)
		"It encodes"
		header_json
		(Jwt.header_to_string (header_fixture Jwt.HS256))


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

let encode_test (data:data) () =
	Alcotest.(check string)
		"encodes"
		data.token
		(Jwt.encode
			data.alg
			secret 
			payload_fixture
		)

let encode =
	data 
		|> List.map 
		(fun d ->
			("It encodes " ^ alg_to_str d.alg, `Quick, encode_test d)
		)


(* Decoding *)

let decode_test (data:data) () =
	Alcotest.(check resultT)
		"decodes"
		(Ok (signed_token_fixture data.alg))
		(Jwt.decode data.token)

let decode_fail_test () =
	Alcotest.(check resultT)
		"it fails to decode"
		(Error "Bad token")
		(Jwt.decode "Monkey")

let decode =
	data
		|> List.map
		(fun d ->
			[
				"It decodes " ^ alg_to_str d.alg, `Quick, decode_test d;
				"It can fail to decode", `Quick, decode_fail_test;
			]
		)
		|> List.flatten

(* Validate *)

let is_valid_true (data:data) () =
	Alcotest.(check bool)
		"true"
		true
		(Jwt.is_valid secret (signed_token_fixture data.alg))

let is_valid_false (data:data) () =
	Alcotest.(check bool)
		"false"
		false
		(Jwt.is_valid "xyz" (signed_token_fixture data.alg))

let is_valid = 
	data
		|> List.map
		(fun d ->
			[
				alg_to_str d.alg ^ " true when valid", `Quick, is_valid_true d;
				alg_to_str d.alg ^ " false when invalid", `Quick, is_valid_false d;
			]
		)
		|> List.flatten

(* Verify *)

let decode_and_verify_ok (data:data) () =
	Alcotest.(check resultT)
		"decodes"
		(Ok (signed_token_fixture data.alg))
		(Jwt.decode_and_verify secret data.token)

let decode_and_verify_err (data:data) () =
	Alcotest.(check resultT)
		"decodes"
		(Error "Invalid token")
		(Jwt.decode_and_verify "xyz" data.token)

let decode_and_verify = 
	data
		|> List.map
		(fun d ->
			[
				alg_to_str d.alg ^ " decode when valid", `Quick, decode_and_verify_ok d;
				alg_to_str d.alg ^ " fails when invalid", `Quick, decode_and_verify_err d;
			]
		)
		|> List.flatten

let () =
	Alcotest.run "JWT" [
		"Encode header", header_to_string;
		"Encode payload", payload_to_string;
		"Encode JWT", encode;
		"Decode token", decode;
		"Validate JWT", is_valid;
		"Decode and verify", decode_and_verify;
	]