//! CLI entry point for the XDR to Zig code generator.

use askama::Template;
use clap::Parser;
use std::collections::HashSet;
use std::fs;
use std::path::PathBuf;
use xdr_generator::generator::Generator;
use xdr_generator::parser;
use xdr_generator::types::Options;

/// XDR to Zig code generator.
#[derive(Parser, Debug)]
#[command(name = "xdr-generator")]
#[command(about = "Generate Zig code from XDR definitions")]
struct Args {
    /// Input XDR files
    #[arg(short, long, required = true)]
    input: Vec<PathBuf>,

    /// Output Zig file
    #[arg(short, long)]
    output: PathBuf,

    /// Types with custom Default implementation (skip default)
    #[arg(long, value_delimiter = ',')]
    custom_default: Vec<String>,

    /// Types with custom string implementation
    #[arg(long, value_delimiter = ',')]
    custom_str: Vec<String>,

    /// Types that should NOT have Display/FromStr generated
    #[arg(long, value_delimiter = ',')]
    no_display_fromstr: Vec<String>,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    // Read all input files and sort by filename (ASCII byte order)
    let mut files: Vec<(PathBuf, String)> = Vec::new();
    for path in &args.input {
        let content = fs::read_to_string(path)?;
        files.push((path.clone(), content));
    }
    files.sort_by(|a, b| a.0.cmp(&b.0));

    // Build combined XDR in sorted order
    let mut combined_xdr = String::new();
    for (_, content) in &files {
        combined_xdr.push_str(content);
        combined_xdr.push('\n');
    }

    // Build input_files list (same order as files for SHA256 hashes)
    let input_files: Vec<(String, String)> = files
        .iter()
        .map(|(path, content)| (path.to_string_lossy().to_string(), content.clone()))
        .collect();

    // Parse the combined XDR
    let spec = parser::parse(&combined_xdr)?;

    // Read the header file
    let header_path = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("header.zig");
    let header = if header_path.exists() {
        fs::read_to_string(&header_path)?
    } else {
        String::new()
    };

    // Build options
    let options = Options {
        custom_default_impl: args.custom_default.into_iter().collect::<HashSet<_>>(),
        custom_str_impl: args.custom_str.into_iter().collect::<HashSet<_>>(),
        no_display_fromstr: args.no_display_fromstr.into_iter().collect::<HashSet<_>>(),
    };

    // Generate the output
    let generator = Generator::new(&spec, options);
    let template = generator.generate(&spec, &input_files, &header);

    // Render the template
    let output = template.render()?;

    // Write the output
    fs::write(&args.output, output)?;

    eprintln!("Generated: {}", args.output.display());

    Ok(())
}
