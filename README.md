# Ocaml JWT

## Create a token

A payload is a list of tuples `(string, string)`:

	let payload =
		[
			("user", "sam);
			("age", "17");
		]

	Jwt.make
		Jwt.HS256
		"secret"
		payload

`Jwt.make` returns a signed token.

## Encode token

	Jwt.make
		Jwt.HS256
		"secret"
		payload
		|> Jwt.encode

## Decode token

Just decode the token, doesn't verify.

	Jwt.decode
		"eyJhbGciOiJIUzI1NiJ9...."

	-->

	Ok { header = ...; payload = [...]; signature = ... }	

## Decode and verify

Verify and decode. If the verification fails you will get an `Error`.

	Jwt.decode_and_verify
		"secret"
		"eyJhbGciOiJIUzI1NiJ9...."

	-->

	Ok { header = ...; payload = [...]; signature = ... }

## Verify only

	Jwt.is_valid
		"secet"
		"eyJhbGciOiJIUzI1NiJ9...."
	
	-->

	true
