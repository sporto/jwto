all:
	opam exec -- dune build --root . @install

test:
	opam exec -- dune runtest --root .

release: all
	opam exec -- dune-release tag
	opam exec -- dune-release distrib
	opam exec -- dune-release publish distrib -y
	opam exec -- dune-release opam pkg
	opam exec -- dune-release opam submit --no-auto-open -y

# Generate odoc documentation
doc:
	opam exec -- dune build --root . @doc
	rm -rf ./docs
	cp -r _build/default/_doc/_html ./docs

# Open odoc documentation with default web browser
servedoc: doc
	open _build/default/_doc/_html/index.html