FROM ocaml/opam2

RUN opam install dune

COPY . .