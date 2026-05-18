#!/usr/bin/env python3

import gzip
import re
import sys
from pathlib import Path


VALID_DB_TYPES = {"silva", "bold", "pr2", "unite", "custom"}
FILL_VALUE = "Unknown"

UNITE_RANK_RE = re.compile(r"([kpcfogs])__([^;]+)")
RANK_PREFIXES = ["k__", "p__", "c__", "o__", "f__", "g__", "s__"]


def log_info(message):
    print(f"[INFO] {message}", file=sys.stderr)


def log_warn(message):
    print(f"[WARN] {message}", file=sys.stderr)


def log_error(message):
    print(f"[ERROR] {message}", file=sys.stderr)


def open_text(path):
    if str(path).endswith(".gz"):
        return gzip.open(path, "rt", encoding="utf-8", errors="replace")
    return open(path, "rt", encoding="utf-8", errors="replace")


def strip_fasta_suffix(path):
    name = path.name
    if name.endswith(".gz"):
        name = name[:-3]
    for suffix in (".fasta", ".fa", ".fna"):
        if name.endswith(suffix):
            return name[: -len(suffix)]
    return Path(name).stem


def normalize_rank(value):
    if value is None:
        return FILL_VALUE
    value = str(value).strip()
    if not value or value.lower() == "none":
        return FILL_VALUE
    value = re.sub(r"\s+", "_", value)
    return value


def normalize_to_7(ranks):
    ranks = [normalize_rank(x) for x in ranks]
    if len(ranks) < 7:
        ranks.extend([FILL_VALUE] * (7 - len(ranks)))
    return ranks[:7]


def format_prefixed_taxonomy(ranks):
    ranks = normalize_to_7(ranks)
    return ";".join(f"{prefix}{rank}" for prefix, rank in zip(RANK_PREFIXES, ranks))


def parse_silva_header(header):
    parts = header.split(None, 1)
    seq_id = parts[0].strip()
    if len(parts) == 1:
        return seq_id, normalize_to_7([])
    tax = [x.strip() for x in parts[1].split(";")]
    return seq_id, normalize_to_7(tax)


def parse_bold_header(header):
    parts = header.split("|")
    seq_id = parts[0].strip()

    if len(parts) < 4:
        log_warn(f"Header BOLD inattendu pour '{seq_id}', taxonomie absente ou incomplète.")
        return seq_id, normalize_to_7([])

    raw_tax = [x.strip() for x in parts[-1].split(",")]

    selected = [
        raw_tax[0] if len(raw_tax) > 0 else None,
        raw_tax[1] if len(raw_tax) > 1 else None,
        raw_tax[2] if len(raw_tax) > 2 else None,
        raw_tax[3] if len(raw_tax) > 3 else None,
        raw_tax[4] if len(raw_tax) > 4 else None,
        raw_tax[6] if len(raw_tax) > 6 else None,
        raw_tax[7] if len(raw_tax) > 7 else None,
    ]
    return seq_id, normalize_to_7(selected)


def parse_pr2_header(header):
    parts = header.split("|")
    seq_id = parts[0].strip()

    if len(parts) <= 4:
        log_warn(f"Header PR2 inattendu pour '{seq_id}', taxonomie absente ou incomplète.")
        return seq_id, normalize_to_7([])

    tax = [x.strip() for x in parts[4:]]

    selected = [
        tax[0] if len(tax) > 0 else None,
        tax[2] if len(tax) > 2 else None,
        tax[4] if len(tax) > 4 else None,
        tax[5] if len(tax) > 5 else None,
        tax[6] if len(tax) > 6 else None,
        tax[7] if len(tax) > 7 else None,
        tax[8] if len(tax) > 8 else None,
    ]
    return seq_id, normalize_to_7(selected)


def parse_unite_header(header):
    parts = header.split("|")
    seq_id = parts[0].strip()

    if len(parts) < 5:
        log_warn(f"Header UNITE inattendu pour '{seq_id}', taxonomie absente ou incomplète.")
        return seq_id, normalize_to_7([])

    taxonomy_field = parts[-1].strip()

    rank_map = {
        "k": FILL_VALUE,
        "p": FILL_VALUE,
        "c": FILL_VALUE,
        "o": FILL_VALUE,
        "f": FILL_VALUE,
        "g": FILL_VALUE,
        "s": FILL_VALUE,
    }

    for rank_code, value in UNITE_RANK_RE.findall(taxonomy_field):
        rank_map[rank_code] = normalize_rank(value)

    selected = [
        rank_map["k"],
        rank_map["p"],
        rank_map["c"],
        rank_map["o"],
        rank_map["f"],
        rank_map["g"],
        rank_map["s"],
    ]
    return seq_id, normalize_to_7(selected)


def parse_custom_header(header):
    parts = header.split("|", 1)
    seq_id = parts[0].strip()

    if len(parts) != 2:
        raise ValueError(
            f"Header CUSTOM invalide pour '{seq_id}'. "
            "Format attendu: >hap|rank1,rank2,rank3,rank4,rank5,rank6,rank7"
        )

    raw_tax = [x.strip() for x in re.split(r"[,;]", parts[1]) if x.strip()]

    if len(raw_tax) != 7:
        raise ValueError(
            f"Header CUSTOM invalide pour '{seq_id}': "
            f"7 rangs attendus, {len(raw_tax)} trouvés."
        )

    return seq_id, normalize_to_7(raw_tax)


def taxonomy_from_header(header, db_type):
    if db_type == "silva":
        return parse_silva_header(header)
    if db_type == "bold":
        return parse_bold_header(header)
    if db_type == "pr2":
        return parse_pr2_header(header)
    if db_type == "unite":
        return parse_unite_header(header)
    if db_type == "custom":
        return parse_custom_header(header)
    raise ValueError(f"Type de base non supporté: {db_type}")


def generate_tax_and_clean_fasta(fasta_path, tax_output_path, clean_fasta_output_path, db_type):
    n_records = 0
    n_missing = 0

    log_info(f"Lecture du FASTA : {fasta_path}")
    log_info(f"Type de base : {db_type}")
    log_info(f"Écriture du fichier tax : {tax_output_path}")
    log_info(f"Écriture du FASTA nettoyé : {clean_fasta_output_path}")

    with open_text(fasta_path) as fasta, \
         open(tax_output_path, "w", encoding="utf-8") as tax_out, \
         open(clean_fasta_output_path, "w", encoding="utf-8") as clean_fasta_out:

        current_seq_id = None
        saw_header = False

        for line_number, line in enumerate(fasta, start=1):
            if line.startswith(">"):
                saw_header = True
                header = line[1:].strip()

                if not header:
                    log_warn(f"Header FASTA vide à la ligne {line_number}, ignoré.")
                    current_seq_id = None
                    continue

                seq_id, ranks = taxonomy_from_header(header, db_type)

                if not seq_id:
                    log_warn(f"Identifiant de séquence vide à la ligne {line_number}, ignoré.")
                    current_seq_id = None
                    continue

                if any(rank == FILL_VALUE for rank in ranks):
                    n_missing += 1

                taxonomy = format_prefixed_taxonomy(ranks)
                tax_out.write(f"{seq_id}\t{taxonomy}\n")

                clean_fasta_out.write(f">{seq_id}\n")
                current_seq_id = seq_id
                n_records += 1
            else:
                if current_seq_id is not None:
                    clean_fasta_out.write(line)

        if not saw_header:
            raise ValueError(f"Aucun header FASTA trouvé dans '{fasta_path}'")

    log_info(
        f"Fichier tax généré : {tax_output_path} "
        f"({n_records} entrées, {n_missing} avec au moins un rang manquant)"
    )
    log_info(f"FASTA nettoyé généré : {clean_fasta_output_path}")


def main():
    if len(sys.argv) != 3:
        log_error("Nombre d'arguments incorrect.")
        print(
            "Usage: generate_tax4refdb.py <reference.fasta> <silva|bold|pr2|unite|custom>",
            file=sys.stderr,
        )
        return 2

    try:
        fasta_path = Path(sys.argv[1]).resolve()
        db_type = sys.argv[2].strip().lower()

        log_info(f"Fichier d'entrée reçu : {fasta_path}")
        log_info(f"Type de base reçu : {db_type}")

        if db_type not in VALID_DB_TYPES:
            log_error(f"Type de base invalide : {db_type}")
            return 1

        if not fasta_path.exists():
            log_error(f"Le fichier n'existe pas : {fasta_path}")
            return 1

        if not fasta_path.is_file():
            log_error(f"Le chemin fourni n'est pas un fichier : {fasta_path}")
            return 1

        base_name = strip_fasta_suffix(fasta_path)
        tax_output_path = f"{base_name}.tax"
        clean_fasta_output_path = f"{base_name}.cleaned.fasta"

        log_info(f"Nom de base détecté : {base_name}")
        log_info(f"Fichier tax de sortie : {tax_output_path}")
        log_info(f"FASTA nettoyé de sortie : {clean_fasta_output_path}")
        log_info("Schéma taxonomique de sortie : k__;p__;c__;o__;f__;g__;s__")

        generate_tax_and_clean_fasta(fasta_path, tax_output_path, clean_fasta_output_path, db_type)
        log_info("Traitement terminé avec succès.")
        return 0

    except ValueError as exc:
        log_error(f"Erreur de contenu : {exc}")
        return 1
    except OSError as exc:
        log_error(f"Erreur système : {exc}")
        return 1
    except Exception as exc:
        log_error(f"Erreur inattendue : {type(exc).__name__}: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())