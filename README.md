# Ocaml JWT

## Create and encode a signed token

A payload is a list of tuples `(string, string)`:

```ocaml
let payload =
  [
    ("user", "sam");
    ("age", "17");
  ]
```

For the signature algorithm, `Jwto` supports HMAC applied to SHA-256 or SHA-512.

We can sign and encode the payload in one go by doing:

```ocaml
Jwto.encode Jwto.HS256 "secret" payload

-->

"eyJhbGciOiJIUzI1NiJ9..."
```

## Decode token

To decode the token without verifying it, and get a `Jwto.t`:

```ocaml
let signed_token =
  match Jwto.decode "eyJhbGciOiJIUzI1NiJ9..." with
  | Ok t -> t
  | Error err -> failwith err

-->

{ header = ...; payload = [...]; signature = ... }	
```

## Verify token

```ocaml
Jwto.is_valid "secret" signed_token

-->

true
```

## Decode and verify

To decode and verify the token in one go:

```ocaml
Jwto.decode_and_verify "secret" "eyJhbGciOiJIUzI1NiJ9..."

-->

Ok { header = ...; payload = [...]; signature = ... }
```

If the verification fails, you will get an `Error`.
