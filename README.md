# Ocaml JWT

## Create a token

A payload is a list of tuples `(string, string)`:

```ocaml
let payload =
  [
    ("user", "sam);
    ("age", "17");
  ]

Jwto.make Jwto.HS256 "secret" payload
```

`Jwto.make` returns a signed token (type Jwto.t):

```ocaml
{
  header = ...;
  payload = [...]; 
  signature = ...;
}
```

## Encode token

```ocaml
Jwto.encode Jwto.HS256 "secret" payload

-->

"eyJhbGciOiJIUzI1NiJ9...."
```

## Decode token

Just decode the token, doesn't verify.

```ocaml
Jwto.decode "eyJhbGciOiJIUzI1NiJ9...."

-->

Ok { header = ...; payload = [...]; signature = ... }	
```

## Decode and verify

Verify and decode. If the verification fails you will get an `Error`.

```ocaml
Jwto.decode_and_verify "secret" "eyJhbGciOiJIUzI1NiJ9...."

-->

Ok { header = ...; payload = [...]; signature = ... }
```

## Verify only

```ocaml
Jwto.is_valid "secet" "eyJhbGciOiJIUzI1NiJ9...."

-->

true
```
