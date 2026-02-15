all: generate

generate: src/curr/generated.zig src/next/generated.zig xdr/curr-version xdr/next-version

src/curr/generated.zig: $(sort $(wildcard xdr/curr/*.x)) xdr-generator/src/*.rs xdr-generator/templates/*.jinja xdr-generator/header.zig
	cargo run --manifest-path xdr-generator/Cargo.toml -- \
		$(addprefix --input ,$(sort $(wildcard xdr/curr/*.x))) \
		--output $@
	zig fmt $@

src/next/generated.zig: $(sort $(wildcard xdr/next/*.x)) xdr-generator/src/*.rs xdr-generator/templates/*.jinja xdr-generator/header.zig
	cargo run --manifest-path xdr-generator/Cargo.toml -- \
		$(addprefix --input ,$(sort $(wildcard xdr/next/*.x))) \
		--output $@
	zig fmt $@

xdr/curr-version: $(wildcard .git/modules/xdr/curr/**/*) $(wildcard xdr/curr/*.x)
	git submodule status -- xdr/curr | sed 's/^ *//g' | cut -f 1 -d " " | tr -d '\n' | tr -d '+' > xdr/curr-version

xdr/next-version: $(wildcard .git/modules/xdr/next/**/*) $(wildcard xdr/next/*.x)
	git submodule status -- xdr/next | sed 's/^ *//g' | cut -f 1 -d " " | tr -d '\n' | tr -d '+' > xdr/next-version

clean:
	rm -f src/curr/generated.zig src/next/generated.zig
	rm -f xdr/curr-version xdr/next-version
	cargo clean --quiet --manifest-path xdr-generator/Cargo.toml

.PHONY: all generate clean
