#!/bin/bash
#SBATCH -J sarek
#SBATCH --partition amilan
#SBATCH -o log/sarek_%j.out  # Output file with the job ID
#SBATCH -e log/sarek_%j.err  # Error file with the job ID
#SBATCH -t 10:00:00   # Set the wall time: D-HH:MM:SS
#SBATCH --qos=normal
#SBATCH -n 1 -c 2  # ask for number of nodes/cores
#SBATCH --mem=8GB  # Specify memory allocation

set -eu  # die on error or undefined variable

# make software accessible:
module load nextflow/25.10.2
module load singularity/3.7.4
sep=----------------------------------------
printf -- "$sep\n%s\n%s\n$sep\n%s\n%s\n$sep\n\n" \
        "$(which nextflow)" "$(nextflow -version)" \
        "$(which singularity)" "$(singularity --version)"

## This overrides the settings in the Nextflow module to keep your stuff
## organized by project:
export NXF_WORK="/scratch/alpine/aassante@xsede.org/nf_core_dir/work"
export NXF_TEMP="/scratch/alpine/aassante@xsede.org/nf_core_dir/tmp"
export NXF_HOME="/scratch/alpine/aassante@xsede.org/nf_core_dir/nextflow"

## Make sample file:
samplefile="/scratch/alpine/aassante@xsede.org/alexis/analysis/exome_SR/02_SR_samples_381_humanonly.csv"
## That CSV file with sample data needs to exist
pipeoutdir="/scratch/alpine/aassante@xsede.org/alexis/analysis/exome_SR/sarekRUN_re"

## nextflow puts everything in $PWD, so make an output dir and go there:
mkdir -p "$pipeoutdir"
cd "$pipeoutdir"

ptargetsbed="/projects/aassante@xsede.org/references/probes_targetregions/S33699751_Padded.bed"
targetsbed="/projects/aassante@xsede.org/references/probes_targetregions/S33699751_Regions.bed"
targets_int="/projects/aassante@xsede.org/references/probes_targetregions/S33699751_Targets.txt"

## make temporary headerless 3-column copy of BED file to play nice with tools:
ln1=$(grep -nPm1 '^chr' "$ptargetsbed" | cut -d : -f 1)
tail -n +"${ln1-1}" "$ptargetsbed" | cut -f 1-3 >"/scratch/alpine/aassante@xsede.org/alexis/analysis/exome_SR/ptargets.bed"

sarek381="/projects/tdanhorn@xsede.org/bbsr/software/nf-core/nf-core-sarek-3.8.1/3_8_1"

igenomebase="/projects/aassante@xsede.org/references/igenomes"

nextflow run "$sarek381" -profile curc_alpine -ansi-log false \
	--wes \
	--input "$samplefile" \
	--genome GATK.GRCh38 \
	--igenomes_base "$igenomebase" \
	--fasta "/projects/aassante@xsede.org/references/igenomes/Homo_sapiens/GATK/GRCh38/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta" \
	--tools mutect2 \
        --trim_fastq \
        --outdir "$pipeoutdir" \
        --multiqc_title sarek381_wes_SR_mappingandvarcalling \
	-resume

