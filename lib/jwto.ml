let ( >> ) f g x = g (f x)

let ( >>= ) result f =
    match result with Error e -> Error e | Ok v -> f v


let map_result f result =
    match result with Error e -> Error e | Ok v -> Ok (f v)


let map_option f option =
    match option with None -> None | Some v -> Some (f v)


let flatten (list : ('a, 'b) result list) =
    List.fold_right
      (fun item acm ->
        match acm with
        | Error e ->
            Error e
        | Ok values ->
          ( match item with
          | Error e ->
              Error e
          | Ok v ->
              Ok (v :: values) ) )
      list
      (Ok [])


type algorithm =
  | HS256
  | HS512
  | Unknown
[@@deriving show, eq]

let fn_for_algorithm alg ~secret str =
    match alg with
    | HS256 ->
        Digestif.SHA256.hmac_string ~key:secret str
        |> Digestif.SHA256.to_raw_string
    | HS512 ->
        Digestif.SHA512.hmac_string ~key:secret str
        |> Digestif.SHA512.to_raw_string
    | Unknown ->
        Digestif.SHA256.hmac_string ~key:secret str
        |> Digestif.SHA256.to_raw_string


let algorithm_to_string (alg : algorithm) : string =
    match alg with
    | HS256 ->
        "HS256"
    | HS512 ->
        "HS512"
    | Unknown ->
        ""


let algorithm_from_string = function
    | "HS256" ->
        HS256
    | "HS512" ->
        HS512
    | _ ->
        Unknown


type header = {
  alg : algorithm;
  typ : string option;
}
[@@deriving show, eq]

let make_header (alg : algorithm) : header = { alg; typ = None }

type payload = (string * string) list [@@deriving show, eq]

type t = {
  header : header;
  payload : payload;
  signature : string;
}
[@@deriving show, eq]

type unsigned_token = {
  header : header;
  payload : payload;
}

let make_unsigned_token (header : header) (payload : payload) =
    { header; payload }


let pp ppf (token : t) = Fmt.pf ppf "%S" (show token)

let eq (a : t) (b : t) : bool = equal a b

let algorithm_from_header h = h.alg

let typ_from_header h = h.typ

let header_to_json (header : header) =
    let alg =
        ( "alg",
          `String
            (algorithm_to_string (algorithm_from_header header))
        )
    in
    let type_ =
        match typ_from_header header with
        | Some typ ->
            [ ("typ", `String typ) ]
        | None ->
            []
    in
    `Assoc (alg :: type_)


let header_to_string = header_to_json >> Yojson.Basic.to_string

let claim_to_json (claim, value) = (claim, `String value)

let payload_to_json payload =
    let members = payload |> List.map claim_to_json in
    `Assoc members


let payload_to_string =
    payload_to_json >> Yojson.Basic.to_string


let b64_url_encode (str : string) : (string, string) result =
    let result =
        Base64.encode
          ~pad:false
          ~alphabet:Base64.uri_safe_alphabet
          str
    in
    match result with
    | Error (`Msg err) ->
        Error err
    | Ok encoded ->
        Ok encoded


let b64_url_decode (str : string) : (string, string) result =
    let result =
        Base64.decode
          ~pad:false
          ~alphabet:Base64.uri_safe_alphabet
          str
    in
    match result with
    | Error (`Msg err) ->
        Error err
    | Ok decoded ->
        Ok decoded


let encode_header (header : header) : (string, string) result =
    header |> header_to_string |> b64_url_encode


let encode_payload (payload : payload) : (string, string) result
    =
    payload |> payload_to_string |> b64_url_encode


let encode_unsigned (unsigned_token : unsigned_token) :
    (string, string) result =
    let b64_header_result =
        encode_header unsigned_token.header
    in
    let b64_payload_result =
        encode_payload unsigned_token.payload
    in
    match (b64_header_result, b64_payload_result) with
    | Ok b64_header, Ok b64_payload ->
        Ok (b64_header ^ "." ^ b64_payload)
    | _ ->
        Error "Unable to encode"


let sign (secret : string) (unsigned_token : unsigned_token) :
    (string, string) result =
    let algo_fn = fn_for_algorithm unsigned_token.header.alg in
    encode_unsigned unsigned_token
    |> map_result (fun encoded_token ->
           algo_fn ~secret encoded_token )


let make_signed_token
    (secret : string) (unsigned_token : unsigned_token) :
    (t, string) result =
    sign secret unsigned_token
    |> map_result (fun signature ->
           {
             header = unsigned_token.header;
             payload = unsigned_token.payload;
             signature;
           } )


let header_from_json json =
    let alg =
        Yojson.Basic.Util.member "alg" json
        |> Yojson.Basic.Util.to_string
    in
    let typ =
        Yojson.Basic.Util.member "typ" json
        |> Yojson.Basic.Util.to_string_option
    in
    { alg = algorithm_from_string alg; typ }


let decode_header = Yojson.Basic.from_string >> header_from_json

let get_claim (claim : string) (payload : payload) :
    string option =
    payload
    |> List.find_opt (fun (c, _) -> c = claim)
    |> map_option (fun (_, v) -> v)


let claim_from_json json : (string * string, string) result =
    match json with
    | claim, `String value ->
        Ok (claim, value)
    | claim, `Int value ->
        Ok (claim, string_of_int value)
    | claim, `Bool value ->
        Ok (claim, string_of_bool value)
    | _ ->
        Error "Bad payload"


let payload_from_json json : (payload, string) result =
    json
    |> Yojson.Basic.Util.to_assoc
    |> List.map claim_from_json
    |> flatten


let decode_payload =
    Yojson.Basic.from_string >> payload_from_json


let encode
    (alg : algorithm) (secret : string) (payload : payload) :
    (string, string) result =
    let header = { alg; typ = None } in
    let unsigned_token = { header; payload } in
    let signature_result = sign secret unsigned_token in
    let unsigned_token_string_result =
        encode_unsigned unsigned_token
    in
    match (signature_result, unsigned_token_string_result) with
    | Error e, _ ->
        Error e
    | _, Error e ->
        Error e
    | Ok signature, Ok unsigned_token_string ->
      ( match b64_url_encode signature with
      | Error e ->
          Error e
      | Ok b64_signature ->
          Ok (unsigned_token_string ^ "." ^ b64_signature) )


let decode_parts
    (header_encoded : string)
    (payload_encoded : string)
    (signature_encoded : string) =
    let payload_result =
        payload_encoded |> b64_url_decode >>= decode_payload
    in
    let header_result =
        header_encoded
        |> b64_url_decode
        |> map_result decode_header
    in
    let signature_result = b64_url_decode signature_encoded in
    match (header_result, payload_result, signature_result) with
    | Ok header, Ok payload, Ok signature ->
        Ok { header; payload; signature }
    | Error err, _, _ ->
        Error ("header : " ^ err)
    | _, Error err, _ ->
        Error ("payload : " ^ err)
    | _, _, Error err ->
        Error ("signature : " ^ err)


let decode (token : string) : (t, string) result =
    try
      let token_splitted =
          Re.Str.split_delim (Re.Str.regexp_string ".") token
      in
      match token_splitted with
      | [ header_encoded; payload_encoded; signature_encoded ]
        ->
          decode_parts
            header_encoded
            payload_encoded
            signature_encoded
      | _ ->
          Error "Bad token"
    with
    | _ ->
        Error "Bad token"


let get_header ({ header; _ } : t) = header

let get_payload ({ payload; _ } : t) = payload

let get_signature ({ signature; _ } : t) = signature

let is_valid (secret : string) (jwt : t) : bool =
    let unsigned =
        { header = jwt.header; payload = jwt.payload }
    in
    match sign secret unsigned with
    | Error _ ->
        false
    | Ok signature ->
        signature = jwt.signature


let verify secret jwt =
    if is_valid secret jwt then
      Ok jwt
    else
      Error "Invalid token"


let decode_and_verify (secret : string) (token : string) :
    (t, string) result =
    token |> decode >>= verify secret
