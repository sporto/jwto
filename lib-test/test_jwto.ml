(* Fixtures *)

exception Fail of string

let ok_or_fail result =
    match result with Ok v -> v | Error e -> raise (Fail e)


let header_json = "{\"alg\":\"HS256\"}"

let payload_fixture =
    [ ("user_id", "some@user.tld"); ("user_name", "user") ]


let secret = "My$ecretK3y"

let header_fixture (alg : Jwto.algorithm) : Jwto.header =
    Jwto.make_header alg


let unsigned_token_fixture (alg : Jwto.algorithm) :
    Jwto.unsigned_token =
    Jwto.make_unsigned_token
      (header_fixture alg)
      payload_fixture


let signed_token_fixture (alg : Jwto.algorithm) : Jwto.t =
    let result =
        Jwto.make_signed_token
          secret
          (unsigned_token_fixture alg)
    in
    match result with
    | Ok signed_token ->
        signed_token
    | Error e ->
        raise (Fail e)


(* Test helpes *)

let alg_to_str = Jwto.algorithm_to_string

let compareT = Alcotest.testable Jwto.pp Jwto.eq

let resultT = Alcotest.result compareT Alcotest.string

(* Test data *)

type data = {
  alg : Jwto.algorithm;
  token : string;
}

let data =
    [
      {
        alg = Jwto.HS256;
        token =
          "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoic29tZUB1c2VyLnRsZCIsInVzZXJfbmFtZSI6InVzZXIifQ.oWQQcNC80L91BVqJya8mSEKwB2-axLjDClVI1lOA85o";
      };
      {
        alg = Jwto.HS512;
        token =
          "eyJhbGciOiJIUzUxMiJ9.eyJ1c2VyX2lkIjoic29tZUB1c2VyLnRsZCIsInVzZXJfbmFtZSI6InVzZXIifQ.VzxiGtU2kDmUAl7P3TcK3GTOdmhrIlhkWTfv09j0qou5Z8LQ29QeqaF-XB4D1LYa0JCXSXlhSEeamFyEEcaNDA";
      };
    ]


(* Test encoding *)

let encode_header () =
    Alcotest.(check string)
      "It encodes"
      header_json
      (Jwto.header_to_string (header_fixture Jwto.HS256))


let header_to_string =
    [ ("Encodes the header", `Quick, encode_header) ]


let empty_payload () =
    Alcotest.(check string)
      "empty"
      "{}"
      (Jwto.payload_to_string [])


let with_payload () =
    Alcotest.(check string)
      "with payload"
      "{\"hello\":\"word\"}"
      (Jwto.payload_to_string [ ("hello", "word") ])


let payload_to_string =
    [
      ("Empty payload", `Quick, empty_payload);
      ("With payload", `Quick, with_payload);
    ]


let encode_test (data : data) () =
    Alcotest.(check string)
      "encodes"
      data.token
      (Jwto.encode data.alg secret payload_fixture |> ok_or_fail)


let encode =
    data
    |> List.map (fun d ->
           ( "It encodes " ^ alg_to_str d.alg,
             `Quick,
             encode_test d ) )


(* Decoding *)

let decode_test (data : data) () =
    Alcotest.(check resultT)
      "decodes"
      (Ok (signed_token_fixture data.alg))
      (Jwto.decode data.token)


let decode_fail_test () =
    Alcotest.(check resultT)
      "it fails to decode"
      (Error "Bad token")
      (Jwto.decode "Monkey")


let decode =
    data
    |> List.map (fun d ->
           [
             ( "It decodes " ^ alg_to_str d.alg,
               `Quick,
               decode_test d );
             ("It can fail to decode", `Quick, decode_fail_test);
           ] )
    |> List.flatten


(* Validate *)

let is_valid_true (data : data) () =
    Alcotest.(check bool)
      "true"
      true
      (Jwto.is_valid secret (signed_token_fixture data.alg))


let is_valid_false (data : data) () =
    Alcotest.(check bool)
      "false"
      false
      (Jwto.is_valid "xyz" (signed_token_fixture data.alg))


let is_valid =
    data
    |> List.map (fun d ->
           [
             ( alg_to_str d.alg ^ " true when valid",
               `Quick,
               is_valid_true d );
             ( alg_to_str d.alg ^ " false when invalid",
               `Quick,
               is_valid_false d );
           ] )
    |> List.flatten


(* Verify *)

let decode_and_verify_ok (data : data) () =
    Alcotest.(check resultT)
      "decodes"
      (Ok (signed_token_fixture data.alg))
      (Jwto.decode_and_verify secret data.token)


let decode_and_verify_err (data : data) () =
    Alcotest.(check resultT)
      "decodes"
      (Error "Invalid token")
      (Jwto.decode_and_verify "xyz" data.token)


let decode_and_verify =
    data
    |> List.map (fun d ->
           [
             ( alg_to_str d.alg ^ " decode when valid",
               `Quick,
               decode_and_verify_ok d );
             ( alg_to_str d.alg ^ " fails when invalid",
               `Quick,
               decode_and_verify_err d );
           ] )
    |> List.flatten


let () =
    Alcotest.run
      "JWT"
      [
        ("Encode header", header_to_string);
        ("Encode payload", payload_to_string);
        ("Encode JWT", encode);
        ("Decode token", decode);
        ("Validate JWT", is_valid);
        ("Decode and verify", decode_and_verify);
      ]
