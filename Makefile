all: generate

generate: src/generated.zig xdr-version

src/generated.zig: $(sort $(wildcard xdr/*.x)) xdr-generator/src/*.rs xdr-generator/templates/*.jinja xdr-generator/header.zig
	cargo run --manifest-path xdr-generator/Cargo.toml -- \
		$(addprefix --input ,$(sort $(wildcard xdr/*.x))) \
		--output $@
	zig fmt $@

xdr-version: $(wildcard .git/modules/xdr/**/*) $(wildcard xdr/*.x)
	git submodule status -- xdr | sed 's/^ *//g' | cut -f 1 -d " " | tr -d '\n' | tr -d '+' > xdr-version

clean:
	rm -f src/generated.zig
	rm -f xdr-version
	cargo clean --quiet --manifest-path xdr-generator/Cargo.toml

.PHONY: all generate clean
