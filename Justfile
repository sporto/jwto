install:
	dune external-lib-deps --missing @runtest

test:
	dune runtest

publish:
	git tag -a 0.2.2
	git push origin 0.2.2
	opam publish