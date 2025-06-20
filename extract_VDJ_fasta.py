from pathlib import Path
from Bio import SeqIO
from collections import defaultdict
import sys

def classify_locus_and_segment(name):
    # Ex: IGHV3-23*01 → locus: IGH, segment: V
    for locus in ("IGH", "IGK", "IGL"):
        if name.startswith(locus):
            remainder = name[len(locus):]
            if remainder.startswith("V"):
                return locus, "V"
            elif remainder.startswith("D"):
                return locus, "D"
            elif remainder.startswith("J"):
                return locus, "J"
    return None, None

def extract_vdj(input_fasta, output_dir):
    output_path = Path(output_dir)

    if not output_path.exists():
        if not output_path.parent.exists():
            raise FileNotFoundError(f"Parent directory of '{output_path}' does not exist.")
        output_path.mkdir()

    # Store records grouped by locus and segment type
    records = defaultdict(list)

    for record in SeqIO.parse(input_fasta, "fasta"):
        locus, segment = classify_locus_and_segment(record.id)
        if locus and segment:
            records[(locus, segment)].append(record)

    # Write to output files by locus and segment
    for (locus, segment), recs in records.items():
        segment_dir = output_path / locus
        segment_dir.mkdir(exist_ok=True)
        out_file = segment_dir / f"{segment}.fasta"
        SeqIO.write(recs, out_file, "fasta")
        print(f"Written {len(recs)} {locus}-{segment} records to {out_file}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python extract_vdj_all_loci.py <path/to/ordb.fasta> <output/folder>")
    else:
        extract_vdj(sys.argv[1], sys.argv[2])
