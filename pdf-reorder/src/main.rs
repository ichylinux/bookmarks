use anyhow::{anyhow, Context, Result};
use clap::Parser;
use lopdf::{Document, Object, ObjectId};
use std::collections::BTreeMap;
use std::path::PathBuf;

/// PDF page reorder tool - rearrange, extract, or duplicate pages in a PDF
#[derive(Parser, Debug)]
#[command(name = "pdf-reorder", version, about, long_about = None)]
struct Args {
    /// Input PDF file
    #[arg(short, long)]
    input: PathBuf,

    /// Output PDF file
    #[arg(short, long)]
    output: PathBuf,

    /// Page order specification (1-based, comma-separated, ranges supported)
    /// Examples:
    ///   "3,1,2"         -> reorder 3 pages
    ///   "1-3,5,7-9"     -> select and reorder with ranges
    ///   "2,2,1"         -> duplicate page 2 and place page 1 last
    #[arg(short, long, value_name = "PAGES")]
    pages: String,
}

/// Parse a page specification string into a list of 1-based page numbers.
/// Supports comma-separated values and ranges like "1-3".
fn parse_pages(spec: &str) -> Result<Vec<u32>> {
    let mut pages = Vec::new();
    for part in spec.split(',') {
        let part = part.trim();
        if part.contains('-') {
            let mut range = part.splitn(2, '-');
            let start: u32 = range
                .next()
                .unwrap()
                .trim()
                .parse()
                .with_context(|| format!("Invalid range start in '{part}'"))?;
            let end: u32 = range
                .next()
                .unwrap()
                .trim()
                .parse()
                .with_context(|| format!("Invalid range end in '{part}'"))?;
            if start == 0 || end == 0 {
                return Err(anyhow!("Page numbers are 1-based; 0 is invalid"));
            }
            if start > end {
                return Err(anyhow!("Range start ({start}) must be <= end ({end})"));
            }
            for p in start..=end {
                pages.push(p);
            }
        } else {
            let p: u32 = part
                .parse()
                .with_context(|| format!("Invalid page number '{part}'"))?;
            if p == 0 {
                return Err(anyhow!("Page numbers are 1-based; 0 is invalid"));
            }
            pages.push(p);
        }
    }
    if pages.is_empty() {
        return Err(anyhow!("No pages specified"));
    }
    Ok(pages)
}

fn reorder_pdf(input: &PathBuf, output: &PathBuf, page_order: &[u32]) -> Result<()> {
    let mut doc = Document::load(input)
        .with_context(|| format!("Failed to load '{}'", input.display()))?;

    let total_pages = doc.get_pages().len() as u32;
    println!("Input PDF: {} pages", total_pages);

    // Validate requested page numbers
    for &p in page_order {
        if p > total_pages {
            return Err(anyhow!(
                "Page {p} does not exist (PDF has {total_pages} pages)"
            ));
        }
    }

    // Build an ordered list of page ObjectIds in the original document
    // doc.get_pages() returns BTreeMap<u32, ObjectId> (1-based page number -> ObjectId)
    let original_pages: BTreeMap<u32, ObjectId> = doc.get_pages();

    // Collect the page ObjectIds in the requested order
    let ordered_ids: Vec<ObjectId> = page_order
        .iter()
        .map(|&p| {
            original_pages
                .get(&p)
                .copied()
                .ok_or_else(|| anyhow!("Page {p} not found in page map"))
        })
        .collect::<Result<Vec<_>>>()?;

    // Rebuild the Pages tree with the new order
    set_pages_order(&mut doc, &ordered_ids)?;

    doc.save(output)
        .with_context(|| format!("Failed to save '{}'", output.display()))?;

    println!(
        "Output PDF: {} pages -> '{}'",
        page_order.len(),
        output.display()
    );
    Ok(())
}

/// Replace the /Kids array of the root Pages object with the new ordered list.
fn set_pages_order(doc: &mut Document, ordered_ids: &[ObjectId]) -> Result<()> {
    // Find the root Pages object id
    let pages_id = doc
        .catalog()
        .context("No catalog found")?
        .get(b"Pages")
        .context("No Pages entry in catalog")?
        .as_reference()
        .context("Pages entry is not a reference")?;

    // Build new Kids array
    let new_kids: Vec<Object> = ordered_ids
        .iter()
        .map(|&id| Object::Reference(id))
        .collect();

    let count = new_kids.len() as i64;

    // Update the Pages dictionary
    let pages_obj = doc
        .get_object_mut(pages_id)
        .context("Pages object not found")?;

    if let Object::Dictionary(ref mut dict) = pages_obj {
        dict.set("Kids", Object::Array(new_kids));
        dict.set("Count", Object::Integer(count));
    } else {
        return Err(anyhow!("Pages object is not a dictionary"));
    }

    // Update each child page's /Parent to point to the root Pages node
    // (they already do, but if pages came from different nodes we ensure consistency)
    for &id in ordered_ids {
        if let Ok(Object::Dictionary(ref mut page_dict)) = doc.get_object_mut(id) {
            page_dict.set("Parent", Object::Reference(pages_id));
        }
    }

    Ok(())
}

fn main() {
    let args = Args::parse();

    let page_order = match parse_pages(&args.pages) {
        Ok(p) => p,
        Err(e) => {
            eprintln!("Error parsing page specification: {e}");
            std::process::exit(1);
        }
    };

    println!(
        "Reordering pages: {:?}",
        page_order
            .iter()
            .map(|p| p.to_string())
            .collect::<Vec<_>>()
            .join(", ")
    );

    if let Err(e) = reorder_pdf(&args.input, &args.output, &page_order) {
        eprintln!("Error: {e}");
        std::process::exit(1);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_simple() {
        assert_eq!(parse_pages("1,2,3").unwrap(), vec![1, 2, 3]);
    }

    #[test]
    fn test_parse_reorder() {
        assert_eq!(parse_pages("3,1,2").unwrap(), vec![3, 1, 2]);
    }

    #[test]
    fn test_parse_range() {
        assert_eq!(parse_pages("1-4").unwrap(), vec![1, 2, 3, 4]);
    }

    #[test]
    fn test_parse_mixed() {
        assert_eq!(parse_pages("1-3,5,7-9").unwrap(), vec![1, 2, 3, 5, 7, 8, 9]);
    }

    #[test]
    fn test_parse_duplicate() {
        assert_eq!(parse_pages("2,2,1").unwrap(), vec![2, 2, 1]);
    }

    #[test]
    fn test_parse_zero_error() {
        assert!(parse_pages("0,1").is_err());
    }

    #[test]
    fn test_parse_invalid_range() {
        assert!(parse_pages("5-3").is_err());
    }

    #[test]
    fn test_parse_empty_error() {
        assert!(parse_pages("").is_err());
    }
}
