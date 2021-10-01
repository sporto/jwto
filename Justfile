install:
	dune external-lib-deps --missing @runtest

test:
	dune runtest

publish:
	dune-release