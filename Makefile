all:
	nix develop -c ninja

clean:
	rm -rf build.ninja .ninja_log outputs
