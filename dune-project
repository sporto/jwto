(lang dune 2.7)

(name jwto)

(license MIT)

(authors "Sebastian Porto")

(maintainers "Sebastian Porto")

(homepage "https://github.com/sporto/jwto")

(bug_reports "https://github.com/sporto/jwto")

(generate_opam_files true)

(package
 (name jwto)
 (synopsis "JWT encoding, decoding and verification")
 (description "JWT encoding, decoding and verification")
 (depends
  (ocaml
   (>= 4.08.0))
  dune
  (digestif
   (>= 1.0.0))
  (fmt
   (>= 0.8))
  (yojson
   (>= 1.6))
  (base64
   (>= 3.1))
  (re
   (>= 1.8))
  (ppx_deriving
   (>= 4.2))
  (alcotest :with-test)
  (odoc :with-doc)))
