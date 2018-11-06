(* The tests *)
let one () =
  Alcotest.(check string) "same chars"  "hellos" (Jwt.encode ~secret:"hello")

let test_set = [
  "Capitalize" , `Quick, one;
]

(* Run it *)
let () =
  Alcotest.run "My first test" [
    "test_set", test_set;
  ]