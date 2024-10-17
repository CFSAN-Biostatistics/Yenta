.PHONY:

.ONESHELL:



usage: ## Show this menu
	@grep -E '^[a-zA-Z_-]+:.*?##.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##"}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

version: ## Show version and branch
	@echo "CSP2 v$${CSP2_VER}/$${CSP2_BRANCH}"

# ENV CSP2_VER=${CSP2_VER}
# ENV BEDTOOLS_VER=${BEDTOOLS_VER}
# ENV MIUMMER_VER=${MUMMER_VER}
# ENV SKESA_VER=${SKESA_VER}
# ENV MASH_VER=${MASH_VER}
# ENV BBMAP_VER=${BBMAP_VER}
# ENV PYTHON_VER=${PYTHON_VER}

versions: version ## Show versions of key installed depedencies
	@echo `nextflow -v`
	@echo `python3 --version` " (container says ${PYTHON_VER})"
	@echo `bedtools --version` " (container says ${BEDTOOLS_VER})"
	@echo "mummer " `mummer --version` " (container says ${MUMMER_VER})"
	@echo `skesa --version 2>&1` " (container says ${SKESA_VER})"
	@echo "mash " `mash --version` " (container says ${MASH_VER})"
	@echo `bbmap.sh --version 2>&1` " (container says ${BBMAP_VER})"

help: ## Show help
	@echo "Citation: CFSAN SNP Pipeline 2, v$${CSP2_VER}, Literman et al. 2024"
	@echo
	@echo "CSP2 is a Nextflow pipeline for rapid, accurate SNP distance estimation"
	@echo "from assembly data."
	@echo 
	@echo "Please see: https://github.com/CFSAN-Biostatistics/CSP2"
	@echo
	@echo "CSP2 runs are managed via Nextflow, providing the user with an array of"
	@echo "customizations while also facilitating module development and additions in"
	@echo "future releases."
	@echo
	@echo "Important Note: The software continues to be focused on the analysis of"
	@echo "groups of bacterial genomes with limited evolutionary differences (<1000"
	@echo "SNPs). Testing is underway to determine how the underlying cluster"
	@echo "diversity impacts distances estimates."
	@echo 
	@echo "CSP2 has two main run modes:"
	@echo "1) "Screening Mode" (screen): Used to determine whether query isolates are"
	@echo "close to a set of reference isolates (e.g., lab control strains, strains"
	@echo "related to an outbreak, etc.) Given one or more user-provided reference"
	@echo "isolates (--ref_reads; --ref_fasta), get alignment statistics and SNP"
	@echo "distances between all reference and query isolates (--reads; --fasta)"
	@echo 
	@echo "2) "SNP Pipeline Mode" (snp): Used to generate pairwise distances and"
	@echo "alignments for a set of query isolates Generate pairwise SNP distances and"
	@echo "alignments for 2+ isolates (--reads; --fasta) based on comparisons to:"
	@echo 
	@echo "One or more user-provided references (--ref_reads; --ref_fasta), or One or"
	@echo "more reference isolates selected by RefChooser (--n_ref)"
	@echo 
	@echo "Usage: screen [options] {--fasta PATH {--reads=PATH | --forward=STR --reverse=STR} --out=PATH}"
	@echo "  or   snp [options] {--fasta {--reads=PATH | --forward=STR --reverse=STR} --out=PATH}"
	@echo 
	@echo "Options:"
	@echo "  --outroot=PATH\tBase directory to create output folder  [default=$CWD] "
	@echo "  --out=PATH\t\tName of the output folder to create (must not exist)"
	@echo "\t\t\t  [default=CSP2_<current_datetime>]"
	@echo "  --forward=STR\t\tFull file extension for forward/left reads of query"
	@echo "\t\t\t  [default='_1.fastq.gz']"
	@echo "  --reverse=STR\t\tFull file extension for reverse/right reads of reference"
	@echo "\t\t\t  [default='_2.fastq.gz']"
	@echo "  --ref_forward=STR\tFull file extension for forward/left reads of reference"
	@echo "\t\t\t  [default='_1.fastq.gz']"
	@echo "  --ref_reverse=STR\tFull file extension for reverse/right reads of reference"
	@echo "\t\t\t  [default='_2.fastq.gz']"
	@echo "  --readext=STR\t\tExtension for single-end reads for query [default='fastq.gz']"
	@echo "  --ref_readext=STR\tExtension for single-end reads for reference"
	@echo "\t\t\t  [default='fastq.gz']"
	@echo "  --min_cov=NUM\t\tDo not analyze queries that cover less than <min_cov>% of the"
	@echo "\t\t\treference assembly [default=85]"
	@echo "  --min_iden=NUM\tOnly consider alignments where the percent identity is at least"
	@echo "\t\t\t  <min_iden> [default=99]"
	@echo "  --min_len=NUM\t\tOnly consider alignments that span at least <min_len> in bp"
	@echo "\t\t\t  [default=500]"
	@echo "  --dwin=LIST\t\tA comma-separated list of windows to check SNP densities"
	@echo "\t\t\t  [default=1000,125,15]"
	@echo "  --wsnps=LIST\t\tThe maximum number of SNPs allowed in the corresponding window from"
	@echo "\t\t\t  --dwin  [default=3,2,1]"
	@echo "  --query_edge=NUM\tOnly consider SNPs that occur within <query_edge>bp of the end"
	@echo "\t\t\t  of a query contig [default=250]"
	@echo "  --ref_edge=NUM\tOnly consider SNPs that occur within <query_edge>bp of the end"
	@echo "\t\t\t  of a reference contig [default=250]"
	@echo "  --n_ref=NUM\t\tThe number of RefChooser reference isolates to consider (only"
	@echo "\t\t\t  applied if using RefChooser) [default=3]"
	@echo "  --reads=PATH\t\tLocation of query read data (Path to directory, or path to file with"
	@echo "\t\t\t  multiple directories)"
	@echo "  --fasta=PATH\t\tLocation of query assembly data (Path to directory containing"
	@echo "\t\t\t  FASTAs, path to FASTA, path to multiple FASTAs)"
	@echo "  --ref_reads=PATH\tLocation of reference read data (Path to directory, or path to"
	@echo "\t\t\t  file with multiple directories)"
	@echo "  --ref_fasta=PATH\tLocation of reference assembly data (Path to directory"
	@echo "\t\t\t  containing FASTAs, path to FASTA, path to multiple FASTAs)"
	@echo "  --trim_name=STR\tA string in assembly file names that you want to remove from"
	@echo "\t\t\t  sample IDs (e.g., _contigs_skesa)"

config:
	@cat <<- EOF
	profiles {
		standard {
			process.executor = 'local'
			params.cores = `nproc --all`
		}
	}
	EOF > ~/.nextflow/config


ifeq (screen, $(firstword $(MAKECMDGOALS)))
	runargs := $(wordlist 2, $(words $(MAKECMDGOALS)), $(MAKECMDGOALS))
	$(eval $(runargs):;@true)
endif

ifeq (snp, $(firstword $(MAKECMDGOALS)))
	runargs := $(wordlist 2, $(words $(MAKECMDGOALS)), $(MAKECMDGOALS))
	$(eval $(runargs):;@true)
endif

screen: config ## determine whether query isolates are close to a reference
	nextflow run CSP2.nf -profile standard --runmode screen $(runargs)

snp: config ## generate pairwise distances for a set of query isolates
	nextflow run CSP2.nf -profile standard --runmode snp $(runargs)

snpdiffs: config

test_screen:
	nextflow run CSP2.nf -profile standard --runmode screen --fasta assets/Screen/Assembly/Week_42_Assembly.fasta --reads assets/Screen/Reads/ --ref_fasta assets/Screen/Assembly/Lab_Control.fasta --out ./CSP2_Test_Screen --readext fq.gz --forward _1.fq.gz --reverse _2.fq.gz

test_snp:
	nextflow run CSP2.nf -profile standard --runmode snp --fasta assets/SNP/ --n_ref 3 --out ./CSP2_Test_SNP --max_missing 50

test: config test_screen test_snp
	ls -lah assets/Screen/Output/Contamination_Screen/
	diff -bur ./CSP2_Test_SNP/snpdiffs assets/SNP/Output/Soil_Analysis/snpdiffs