# Load required libraries
library("phyloseq")
library("ggplot2")
library("gridExtra")
library("edgeR")
library("vegan")
library("microbiome")
library("knitr")
library("ggpubr")
library("reshape2")
library("RColorBrewer")
library("microbiomeutilities")
library("viridis")
library("tibble")
library("ps")
library("randomcoloR")

# Set working directory
setwd("E:/vinay/STP_P2")

# Define the biom table file
slashpile_16sV1V3 <- "OTU_S_Merged.biom"

# Import and preprocess the biom table
s16sV1V3 = import_biom(BIOMfilename = slashpile_16sV1V3, parseFunction = parse_taxonomy_default)
colnames(tax_table(s16sV1V3)) <- c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus")

# Display some information about the data
head(otu_table(s16sV1V3))
head(sample_data(s16sV1V3))
summarize_phyloseq(s16sV1V3)

# Create a new variable for downstream analysis
ps1 <- s16sV1V3
summarize_phyloseq(ps1)

# Check for OTUs not present in any sample and remove them
any(taxa_sums(ps1) == 0)
ps1a <- prune_taxa(taxa_sums(ps1) > 0, ps1)
any(taxa_sums(ps1a) == 0)

# Display information about the data after removing OTUs
ntaxa(ps1)
ntaxa(ps1a)
ntaxa(ps1) - ntaxa(ps1a)
rank_names(ps1a)

# Create a new variable for downstream analysis with singletons removed
ps1b <- prune_taxa(taxa_sums(ps1a) > 0, ps1a)
summarize_phyloseq(ps1b)

# Check the distribution of OTUs
hist(log10(taxa_sums(ps1a)))

# Plot OTU prevalence
prev.otu <- plot_taxa_prevalence(ps1b, "Rank1")
print(prev.otu)

# Calculate and plot alpha diversity (Shannon and Simpson indices)
alpha_meas = c("simpson", "shannon")
p <- plot_richness(ps1a, "Location", "Month", measures = alpha_meas)
p + geom_boxplot(data = p$data, aes(x = Month, y = value, color = NULL), alpha = 0.1)

# Calculate and plot beta diversity
nsamples(ps1b)
ps4 <- core(ps1a, detection = 0, prevalence = 0 / nsamples(ps1b))
ps4.rel <- microbiome::transform(ps4, "compositional")
bx.ord_pcoa_bray <- ordinate(ps4.rel, "PCoA", "bray")

# Create beta diversity plots
beta.ps1 <- plot_ordination(ps4.rel, bx.ord_pcoa_bray, color = "Month", label = "Location") + 
  geom_point(aes(shape = Month), size = 4) + 
  theme(plot.title = element_text(hjust = 0, size = 12)) +
  theme_bw(base_size = 14) + 
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

beta.ps2 <- beta.ps1 + geom_line() + scale_color_brewer(palette = "Dark2")

beta.ps3 <- plot_ordination(ps4.rel, bx.ord_pcoa_bray, color = "Month", label = "Location") + 
  geom_point(aes(shape = Month), size = 4) + 
  theme(plot.title = element_text(hjust = 0, size = 12)) +
  theme_bw(base_size = 14) + 
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  scale_color_brewer(palette = "Dark2") + stat_ellipse()

# Display beta diversity plots
beta.ps1
beta.ps2
beta.ps3
