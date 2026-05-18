# Documentation Technique et Guide Utilisateur : Pipeline `OpenMetaBar`

## 1. Introduction et Vision Stratégique

Le pipeline **nf-core/openmetabar** est une architecture bio-informatique avancée conçue pour le traitement unifié des données de métabarcoding. Développé en **Nextflow DSL2**, ce workflow est intrinsèquement *container-native* et repose sur une logique de canaux asynchrones, garantissant une extensibilité et une performance optimales pour les technologies :

* **Illumina**
* **PacBio**
* **Oxford Nanopore (ONT)**

L'entrée principale s'effectue via `main.nf`, qui initialise le workflow `OPENMETABAR`. Cette solution automatise l'intégralité de la chaîne analytique — du démultiplexage brut à l'assignation taxonomique et l'analyse phylogénétique. Pour un architecte de solutions, cette transition d'un traitement manuel vers un pipeline orchestré est le garant de l'intégrité des données à haut débit et de la conformité aux standards de la plateforme **IDMABIO**.

---

## 2. Spécifications des Données d'Entrée (Design File)

Le pilotage du pipeline est centralisé par le fichier de design (*samplesheet*), qui sert de source de vérité pour le module `PARSE_FILE`. Ce module valide les entrées et prépare dynamiquement les métadonnées pour **Lotus3**.

### Structure des Données et Colonnes Étendues

Le tableau suivant décrit les colonnes obligatoires (indices 0 à 5). Les colonnes supplémentaires (à partir de l'indice 6) sont automatiquement propagées dans le fichier de mapping final (`mymap.txt`).

| Colonne | Description | Impact Technique |
| --- | --- | --- |
| **Sample_ID** | Identifiant unique | Nettoyage automatique : les tirets (`-`) sont convertis en underscores (`_`). |
| **fastq_path** | Chemin du fichier FASTQ | Vérification d'existence et dédoublonnement via canaux Nextflow. |
| **barcodeF** | Barcode Forward | Utilisé par **Minibar** pour le démultiplexage. |
| **barcodeR** | Barcode Reverse | Utilisé par **Minibar** pour le démultiplexage. |
| **primerF** | Amorce Forward | Utilisée pour le filtrage et le mapping Lotus3. |
| **primerR** | Amorce Reverse | Utilisée pour le filtrage et le mapping Lotus3. |
| **...** | Modalités (Extra) | Toute colonne supplémentaire est incluse dans `extra_header`. |

> [!IMPORTANT]
> **Rigueur du Parsing :**
> * **Démultiplexage Conditionnel :** Le fichier `barcode.txt` est généré uniquement si `params.demux` est activé. Sinon, un fichier vide est créé.
> * **Validation d'En-tête :** Le pipeline s'arrête immédiatement si l'une des six colonnes obligatoires est manquante.
> 
> 

---

## 3. Architecture du Workflow et Logique de Décision

Le workflow oriente les données vers des sous-workflows spécifiques en fonction du couple `params.techno` et `params.marker`.

### Flux de Travail et Conditions de Déclenchement

L'exécution est routée selon des correspondances de chaînes de caractères strictes :

* **ONT_IDMABIO** : Activé si `params.techno == 'ont'` et `params.marker == 'COI-idmabio'`.
* **PACBIO_16S** : Activé si `params.techno == 'pacbio'` et `params.marker == '16s'`.
* **ILLUMINA_LSU_ITS_16S** : Valeur par défaut pour la technologie `illumina`.

---

## 4. Détail des Étapes de Traitement (Core Modules)

### MINIBAR (Démultiplexage)

Sépare les lectures en appliquant des tolérances d'erreur définies dans `nextflow.config` :

* `-e 0` : Tolérance zéro sur les barcodes (assignation stricte).
* `-E 4` : 4 erreurs autorisées pour les amorces (primers).

### LENGTHS_FILTER (Filtrage de Qualité)

Utilisation de `seqkit` pour appliquer une plage de tolérance de **±10%** autour de la valeur `expected_lengths` :


$$Min = \text{round}(len \times 0.9)$$

$$Max = \text{round}(len \times 1.1)$$

### BUILD_MAPPING_FILE

Assure la transition vers Lotus3 avec une fonction de **"self-healing"** :

* Vérification par `[[ -s "$f" ]]`.
* Les fichiers FASTQ vides sont écartés.
* Production d'un résumé dans `fastq_summary.txt`.

### LOTUS3 (Analyse Taxonomique)

Adaptation dynamique des fichiers de configuration (SDM) :

* **PacBio + 16S** : `sdm_PacBio_LSSU.txt`
* **ONT** : `sdm_ONT_LSSU.txt`
* **Illumina** : `sdm_miSeq_ITS.txt`

---

## 5. Guide de Configuration et Paramétrage

### Paramètres Critiques

| Catégorie | Options Autorisées |
| --- | --- |
| **Clustering** (`params.clustering`) | `unoise` (défaut), `uparse`, `swarm`, `cdhit`, `dada2`, `vsearch` |
| **Alignement** (`params.taxAligner`) | `blast` (défaut), `rdp_classifier`, `lambda`, `utax`, `sintax`, `vsearch`, `usearch` |
| **Filtrage** | `filter` (Boolean), `expected_lengths` (List, ex: `[658]`) |

---

## 6. Sorties, Reporting et Traçabilité

### Module REPORT

Génère un document `report_idmabio.docx` via `generate_report.py`.

* **Note :** Les sections relatives à l'extraction d'ADN contiennent des *placeholders*. Le biologiste doit compléter manuellement les détails expérimentaux.

### Traçabilité Logicielle

Les versions exactes des outils sont compilées dans :
`pipeline_info/openmetabar_software_versions.yml`

---

## 7. Recommandations et Bonnes Pratiques

1. **Vérification post-parsing** : Examinez systématiquement `fastq_summary.txt` pour confirmer les échantillons retenus.
2. **Validation du Design** : Évitez les caractères spéciaux dans les colonnes "extra" pour ne pas corrompre `mymap.txt`.
3. **Citation et Conformité** : Obligation de citer la plateforme **IDMABIO** et l'infrastructure **PlantBios** (DOI: [10.15454/qyey-ar89](https://www.google.com/search?q=https://doi.org/10.15454/qyey-ar89)).

---

*Document généré en 2026*