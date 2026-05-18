import pandas as pd
from Bio import SeqIO
import sys

# Input
fichier_OTU = sys.argv[1]
fichier_seq = sys.argv[2]
fichier_taxo = sys.argv[3]
fichier_blast = sys.argv[4]

#print(fichier_OTU)
#print(fichier_seq)
#print(fichier_taxo)
#print(fichier_blast)

df = pd.read_csv(fichier_OTU, sep="\t", index_col=0)
taxo_df = pd.read_csv(fichier_taxo, sep="\t", index_col=0)
blast = pd.read_csv(fichier_blast, sep="\t", header=None)
blast.columns = [
    "ZOTU", "REF_db", "Percent_ID", "Alignment_length",
    "Mismatch", "Gap", "Qstart", "Qend",
    "Sstart", "Send", "Bitscore"
]

best_hits = blast.loc[blast.groupby("ZOTU")["Percent_ID"].idxmax()]

### add seq
zotu_sequences = {}
for record in SeqIO.parse(fichier_seq, "fasta"):
    zotu_id = record.id
    zotu_sequences[zotu_id] = str(record.seq)

best_hits = best_hits.set_index("ZOTU")
best_hits_annot = best_hits.merge(
    taxo_df[['Domain', 'Phylum', 'Class', 'Order', 'Family', 'Genus', 'Species']],
    left_index=True,
    right_index=True,
    how="left"
)

df_filtre = df[df.sum(axis=1) >= 5]

resultats = []
for sample in df_filtre.columns:
    
    top_candidates = df_filtre[sample].sort_values(ascending=False)
    selected = []
    taxo_seen = set()

    for zotu, abundance in top_candidates.items():
        
        if abundance == 0:
            continue
        
        if zotu in best_hits_annot.index:
            annot = best_hits_annot.loc[zotu]
            
            taxo_tuple = (
                annot["Domain"],
                annot["Phylum"],
                annot["Class"],
                annot["Order"],
                annot["Family"],
                annot["Genus"],
                annot["Species"]
            )
        else:
            taxo_tuple = ("NA", "NA", "NA", "NA", "NA", "NA", "NA")
        
        if len(taxo_seen) < 4 or taxo_tuple in taxo_seen:
            selected.append((zotu, abundance))
            taxo_seen.add(taxo_tuple)
        
        if len(taxo_seen) == 4 or len(selected) == 10:
            break
    
    for rank, (zotu, abundance) in enumerate(selected, start=1):
        
        if abundance == 0:
            continue
        
        seq_zotu = zotu_sequences.get(zotu, "NA")
        
        if zotu in best_hits_annot.index:
            annot = best_hits_annot.loc[zotu]
            resultats.append({
                "Sample": sample,
                "Rank": rank,
                "ZOTU": zotu,
                "Abundance": abundance,
                "REF_db": annot["REF_db"],
                "Percent_ID": annot["Percent_ID"],
                "Aligment_length": annot["Alignment_length"],
                "Gap": annot["Gap"],
                "Domain": annot["Domain"],
                "Phylum": annot["Phylum"],
                "Class": annot["Class"],
                "Order": annot["Order"],
                "Family": annot["Family"],
                "Genus": annot["Genus"],
                "Species": annot["Species"],
                "ZOTU_sequence": seq_zotu,
            })
        else:
            resultats.append({
                "Sample": sample,
                "Rank": rank,
                "ZOTU": zotu,
                "Abundance": abundance,
                "REF_db": "NA",
                "Percent_ID": "NA",
                "Aligment_length": "NA",
                "Gap": "NA",
                "Domain": "NA",
                "Phylum": "NA",
                "Class": "NA",
                "Order": "NA",
                "Family": "NA",
                "Genus": "NA",
                "Species": "NA",
                "ZOTU_sequence": seq_zotu,
            })

df_final = pd.DataFrame(resultats)

df_final.to_csv("Table_Top_ZOTU_per_sample.csv", sep = "\t",index=False)