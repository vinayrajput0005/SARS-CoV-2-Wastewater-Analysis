#!/bin/bash

# Default values
reference_genome="Wuhan-Hu-1_MN908947.3.fasta"
annotation_file="sequence.gff3"
output_directory="/media/ncim/Expansion/SARS-CoV-2_Bioinformatics/"

# Function to display script usage
usage() {
    echo "Usage: $0 [-g <reference_genome>] [-a <annotation_file>] [-o <output_directory>]"
    echo "Options:"
    echo "  -g <reference_genome>: Path to the reference genome file (default: $reference_genome)"
    echo "  -a <annotation_file>: Path to the GFF3 annotation file (default: $annotation_file)"
    echo "  -o <output_directory>: Path to the output directory (default: $output_directory)"
    exit 1
}

# Parse command-line options
while getopts ":g:a:o:h" opt; do
    case $opt in
        g)
            reference_genome="$OPTARG"
            ;;
        a)
            annotation_file="$OPTARG"
            ;;
        o)
            output_directory="$OPTARG"
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

shift $((OPTIND-1))

# Define text formatting variables
red=$(tput setaf 1)
green=$(tput setaf 2)
reset=$(tput sgr0)

# Define an array of sample names
declare -a samples=("IP12991" "IP12999" "IP13007" "IP13015" "IP13023" "IP13031" "IP13039" "IP13047" "IP13055" "IP13063")

# Iterate through each sample
for sample in "${samples[@]}"; do
    echo "${red}SARS-CoV-2 Bioinformatics analysis: Illumina${reset}"
    echo "Sample: $sample"

    # Activate the Conda ivar environment
    #source activate /home/ncim/anaconda3/envs/ivar

    echo "${red}Step 1: Unzipping the files${reset}"
    gunzip "${sample}"*

    echo "${red}Step 2: Concatenation of fastq files${reset}"
    cat "${sample}"*.fastq >"${sample}.fastq"

    # Create a directory for this sample
    sample_directory="trim_${sample}"
    mkdir -p "$sample_directory"

    # Move files and copy reference genome and annotation file
    mv "${sample}.fastq" "$sample_directory/"
    cp "${output_directory}${annotation_file}" "${output_directory}Wuhan-Hu-1_MN908947.3.fasta" "$sample_directory/"

    # Change to the sample directory
    cd "$sample_directory"

    echo "${red}Step 3: Quality Checking of Reads using fastp tool${reset}"
    fastp -i "${sample}.fastq" -o "${sample}_fp.fastq"

    echo "${red}Step 4: Indexing Reference SARS-CoV-2 Genome${reset}"
    bwa index "${reference_genome}"

    echo "${red}Step 5: Alignment using BWA${reset}"
    bwa mem "${reference_genome}" "${sample}_fp.fastq" >"${sample}_fp.sam"

    echo "${red}Step 6: SAM to BAM${reset}"
    samtools view -S -b "${sample}_fp.sam" >"${sample}_fp.bam"

    echo "${red}Step 7: Sorting of BAM file${reset}"
    samtools sort -o "${sample}_fp_sorted.bam" "${sample}_fp.bam"

    echo "${red}Step 8: Alignment Stats${reset}"
    samtools flagstat "${sample}_fp_sorted.bam" >"Alignment_Stat.txt"

    echo "${red}Step 9: Variant Calling using ivar${reset}"
    samtools mpileup -A -d 0 -B -Q 0 "${sample}_fp_sorted.bam" | ivar variants -m 10 -r "${reference_genome}" -g "${annotation_file}" -p ivar_out

    echo "${red}Analysis Done for sample: $sample${reset}"
    
    # Go back to the parent directory
    cd ..
done

