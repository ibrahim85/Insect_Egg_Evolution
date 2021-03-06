### This code assembles the final tables for the supplement

library(xtable)
source("analyze_data/egg_analysis_build_dataframe.R")
results_directory <- "results_Feb2019"

### MODEL FITTING
load(paste(results_directory,"egg_analysis_model_fitting.Rdata",sep="/"))

summary_fit_table <- fit_table %>% mutate(trait = row.names(.)) %>% 
	rowwise %>% 
	mutate(min_val = min(c(BM,OU,EB,WN))) %>%
	mutate('DeltaAICc, BM' = BM - min_val,
	'DeltaAICc, OU' = OU - min_val,
	'DeltaAICc, EB' = EB - min_val,
	'DeltaAICc, WN' = WN - min_val) %>% 
	select('DeltaAICc, BM','DeltaAICc, OU','DeltaAICc, EB','DeltaAICc, WN')
row.names(summary_fit_table) <- row.names(fit_table)
print(xtable(summary_fit_table),file="summary_fit_table_latex.txt")

### ALL ALLOMETRY RESULTS

## size shape allometry
load(paste(results_directory,"egg_analysis_allometry_workspace.Rdata",sep="/"))

read_pgls_results <- function(all_taxa,by_group,group_list) {
	observed_all_taxa<- round(all_taxa,2)
	summary_table  <- lapply(by_group,round,2) %>% 
		plyr::ldply() %>% 
		rbind(observed_all_taxa,.) %>% 
		mutate("p-value" = paste(pval_min,pval_max,sep=" - "),
			"intercept" = paste(int_min,int_max,sep=" - "),
			"slope" = paste(slope_min,slope_max,sep=" - "),
			"sample size" = sample_size) %>% 
		select("p-value","slope","intercept","sample size")
	row.names(summary_table) <- c("Hexapoda",group_list)
	return(summary_table)
}

print(xtable(read_pgls_results(allometry_l_asym_w_table,allometry_group_l_asym_w_table,group_list),digits=0),file="allometry_l_asym_w_table_latex.txt")
print(xtable(read_pgls_results(allometry_l_curv_w_table,allometry_group_l_curv_w_table,group_list),digits=0),file="allometry_l_curv_w_table_latex.txt")
print(xtable(read_pgls_results(allometry_l_w_body_table,allometry_group_l_w_body_table,group_list),digits=0),file="allometry_l_w_body_table_latex.txt")
print(xtable(read_pgls_results(allometry_vol_body_table,allometry_group_vol_body_table,group_list),digits=0),file="allometry_vol_body_table_latex.txt")
print(xtable(read_pgls_results(allometry_l_w_table,allometry_group_l_w_table,group_list),digits=0),file="allometry_l_w_table_latex.txt")

summary_l_w <- read_pgls_results(allometry_l_w_table,allometry_group_l_w_table,group_list) %>% mutate(clade = row.names(.),analysis = "egg length vs width")
summary_l_asym_w <- read_pgls_results(allometry_l_asym_w_table,allometry_group_l_asym_w_table,group_list)%>% mutate(clade = row.names(.),analysis = "egg length vs asymmetry, residuals to egg width")
summary_l_curv_w <- read_pgls_results(allometry_l_curv_w_table,allometry_group_l_curv_w_table,group_list) %>% mutate(clade = row.names(.),analysis = "egg length vs angle of curvature, residuals to egg width")
summary_l_w_body <- read_pgls_results(allometry_l_w_body_table,allometry_group_l_w_body_table,group_list) %>% mutate(clade = row.names(.),analysis = "egg length vs width, residuals to body size")
summary_vol_body <- read_pgls_results(allometry_vol_body_table,allometry_group_vol_body_table,group_list) %>% mutate(clade = row.names(.),analysis = "egg volume vs cubic body length")

## development
load(paste(results_directory,"egg_analysis_development_workspace.Rdata",sep="/"))

summary_development <- rbind(round(allometry_vol_Da_hatch_table,2),
	round(allometry_vol_Da_int_btw_preblast_mitoses_table,2),
	round(allometry_vol_Da_time_midcellularization,2)) %>% 
	mutate("p-value" = paste(pval_min,pval_max,sep=" - "),
		"intercept" = paste(int_min,int_max,sep=" - "),
		"slope" = paste(slope_min,slope_max,sep=" - "),
		"sample size" = round(sample_size,0)) %>% 		
	select("p-value","slope","intercept","sample size")
row.names(summary_development) <- c("egg volume vs duration of embryogenesis","egg volume vs interval between pre-blastoderm mitoses","egg volume vs time to cellularization")

print(xtable(summary_development,digits=0),file="summary_development_latex.txt")

egg_vol <- egg_database %>% mutate(trait1 = logvol)
dev_hatch <- development %>% mutate(trait2 = logDa_hatch) %>% filter(dipause != "y")
dat_vol_Da_hatch <- combine_dev_egg_datasets(egg_vol,dev_hatch)
non_phylo_dev_regression <- summary(lm(trait1~trait2, dat_vol_Da_hatch))

sink(file="nonphylogenetic_regression_development_latex.txt")
non_phylo_dev_regression
sink()

## genome size
load(paste(results_directory,"egg_analysis_genome_size_egg_size_workspace.Rdata",sep="/"))

summary_genome_vol <- read_pgls_results(genome_vol_table,genome_vol_group_table,group_list) %>% mutate(clade = row.names(.))
summary_genome_vol_genus <- read_pgls_results(genome_vol_genus_table,genome_vol_genus_group_table,group_list) %>% mutate(clade = row.names(.))
summary_genome_vol_no_Polyneoptera <- genome_vol_no_Polyneoptera_table %>% mutate("p-value" = paste(pval_min,pval_max,sep=" - "),
		"intercept" = paste(int_min,int_max,sep=" - "),
		"slope" = paste(slope_min,slope_max,sep=" - "),
		"sample size" = round(sample_size,0),
		"clade" = "Hexapoda, w/o Polyneoptera") %>% 		
		select("p-value","slope","intercept","sample size","clade")
summary_genome_size <- rbind(rbind(summary_genome_vol,summary_genome_vol_genus[1,] %>% mutate(clade = "Hexapoda, by genus")),summary_genome_vol_no_Polyneoptera)

print(xtable(summary_genome_size,digits=0),include.rownames=F,file="summary_genome_size_latex.txt")

### BODY SIZE ALLOMETRY
load(paste(results_directory,"egg_analysis_allometry_workspace.Rdata",sep="/"))

observed_slope_vol_body <- slope_dist_vol_body_vol

load(paste(results_directory,"slope_1_egg_analysis_simulate_body_workspace.Rdata",sep="/"))
simulated_1_vol_bodyvol_table <- round(allometry_all_taxa_table,2)
simulated_group_1_vol_bodyvol_table <- round(rbind(allometry_Hymenoptera_table,
							allometry_Condylognatha_table,
							allometry_Antliophora_table,
							allometry_Neuropteroidea_table,
							allometry_Amphiesmenoptera_table,
							allometry_Polyneoptera_table,
							allometry_Palaeoptera_table),2)
row.names(simulated_group_1_vol_bodyvol_table) <- c("Hymenoptera","Condylognatha","Antliophora","Neuropteroidea","Amphiesmenoptera","Polyneoptera","Palaeoptera")
simulated_1_slope_vol_body <- slope_dist_vol_bodyvol

load(paste(results_directory,"slope_0_egg_analysis_simulate_body_workspace.Rdata",sep="/"))
simulated_0_vol_bodyvol_table <- round(allometry_all_taxa_table,2)
simulated_group_0_vol_bodyvol_table <- round(rbind(allometry_Hymenoptera_table,
							allometry_Condylognatha_table,
							allometry_Antliophora_table,
							allometry_Neuropteroidea_table,
							allometry_Amphiesmenoptera_table,
							allometry_Polyneoptera_table,
							allometry_Palaeoptera_table),2)
row.names(simulated_group_0_vol_bodyvol_table) <- c("Hymenoptera","Condylognatha","Antliophora","Neuropteroidea","Amphiesmenoptera","Polyneoptera","Palaeoptera")
simulated_0_slope_vol_body <- slope_dist_vol_bodyvol

median_observed_slope_vol_body <- observed_slope_vol_body %>% group_by(L1) %>% summarise(value = median(value)) %>% mutate("dataset" = "test statistic")

simulated_1_slope_vol_body$dataset <- "slope 1"
simulated_0_slope_vol_body$dataset <- "slope 0"
observed_slope_vol_body$dataset <- "observed"
summary_slope_vol_body <- rbind(observed_slope_vol_body,simulated_1_slope_vol_body,simulated_0_slope_vol_body)

slope_vol_body_plot <- ggplot(summary_slope_vol_body,aes(x = factor(L1,levels=group_levels), y = value, color = factor(dataset,levels=c("slope 0","observed","slope 1")), fill = dataset)) + 
	geom_abline(intercept=1.0,slope=0,color="black",linetype=2) +
	geom_boxplot(data = median_observed_slope_vol_body,color = "black",fill= "black",outlier.size=0,coef=0) +
	geom_jitter(position=position_jitterdodge(jitter.width = 0.35, jitter.height = 0, dodge.width = 0.5),size=0.5) + 
	scale_fill_manual(values = c("#2056CE","dark gray","#c55c15","black")) + 
	scale_color_manual(values = c("#2056CE","dark gray","#c55c15","black")) +
	theme(legend.position="none") + ylab("slope") + xlab("clade")

pdf(file="parametric_boostrap_vol_body_plot.pdf",width=8,height=4)
print(slope_vol_body_plot)
dev.off()

p_value_slope_1_vol_body <- data.frame(L1 = median_observed_slope_vol_body$L1, ts = median_observed_slope_vol_body$value,stringsAsFactors=F) %>% right_join(.,simulated_1_slope_vol_body,by="L1") %>% group_by(L1) %>% summarize("p-value, isometry" = (sum(value < max(ts))/100))
p_value_slope_0_vol_body <- data.frame(L1 = median_observed_slope_vol_body$L1, ts = median_observed_slope_vol_body$value,stringsAsFactors=F) %>% right_join(.,simulated_0_slope_vol_body,by="L1") %>% group_by(L1) %>% summarize("p-value, no relationship" = (sum(value > max(ts))/100))
summary_simulation_vol_body_table <- median_observed_slope_vol_body %>% rename("test statistic" = value) %>% select(L1,"test statistic") %>% 
		left_join(.,p_value_slope_1_vol_body,by="L1") %>% 
		left_join(.,p_value_slope_0_vol_body,by="L1") %>% 
		arrange(match(L1,group_levels))
row.names(summary_simulation_vol_body_table) <- summary_simulation_vol_body_table$L1
summary_simulation_vol_body_table <- summary_simulation_vol_body_table %>% select(-L1)

print(xtable(summary_simulation_vol_body_table),file="bootstrap_vol_bodyvol_latex.txt")


### LENGTH WIDTH ALLOMETRY
load(paste(results_directory,"egg_analysis_allometry_workspace.Rdata",sep="/"))

observed_slope_l_w <- slope_dist_l_w

load(paste(results_directory,"slope_1_egg_analysis_simulate_allometry_workspace.Rdata",sep="/"))
simulated_1_l_w_table <- round(allometry_all_taxa_table,2)
simulated_group_1_l_w_table <- round(rbind(allometry_Hymenoptera_table,
							allometry_Condylognatha_table,
							allometry_Antliophora_table,
							allometry_Neuropteroidea_table,
							allometry_Amphiesmenoptera_table,
							allometry_Polyneoptera_table,
							allometry_Palaeoptera_table),2)
simulated_1_slope_l_w <- slope_dist_l_w

load(paste(results_directory,"slope_0_egg_analysis_simulate_allometry_workspace.Rdata",sep="/"))
simulated_0_l_w_table <- round(allometry_all_taxa_table,2)
simulated_group_0_l_w_table <- round(rbind(allometry_Hymenoptera_table,
							allometry_Condylognatha_table,
							allometry_Antliophora_table,
							allometry_Neuropteroidea_table,
							allometry_Amphiesmenoptera_table,
							allometry_Polyneoptera_table,
							allometry_Palaeoptera_table),2)
simulated_0_slope_l_w <- slope_dist_l_w

median_observed_slope_l_w <- observed_slope_l_w %>% group_by(L1) %>% summarise(value = median(value)) %>% mutate("dataset" = "test statistic")

simulated_1_slope_l_w$dataset <- "slope 1"
simulated_0_slope_l_w$dataset <- "slope 0"
observed_slope_l_w$dataset <- "observed"
summary_slope_l_w <- rbind(observed_slope_l_w,simulated_1_slope_l_w,simulated_0_slope_l_w)

slope_l_w_plot <- ggplot(summary_slope_l_w,aes(x = factor(L1,levels=group_levels), y = value, color = factor(dataset,levels=c("slope 0","observed","slope 1")), fill = dataset)) + 
	geom_abline(intercept=1.0,slope=0,color="black",linetype=2) +
	geom_boxplot(data = median_observed_slope_l_w,color = "black",fill= "black",outlier.size=0,coef=0) +
	geom_jitter(position=position_jitterdodge(jitter.width = 0.35, jitter.height = 0, dodge.width = 0.5),size=0.5) + 
	scale_fill_manual(values = c("#2056CE","dark gray","#c55c15","black")) + 
	scale_color_manual(values = c("#2056CE","dark gray","#c55c15","black")) +
	theme(legend.position="none") + ylab("slope") + xlab("clade")

pdf(file="parametric_boostrap_l_w_plot.pdf",width=8,height=4)
print(slope_l_w_plot)
dev.off()


p_value_slope_1_l_w <- data.frame(L1 = median_observed_slope_l_w$L1, ts = median_observed_slope_l_w$value,stringsAsFactors=F) %>% right_join(.,simulated_1_slope_l_w,by="L1") %>% group_by(L1) %>% summarize("p-value, isometry" = (sum(value < max(ts))/100))
p_value_slope_0_l_w <- data.frame(L1 = median_observed_slope_l_w$L1, ts = median_observed_slope_l_w$value,stringsAsFactors=F) %>% right_join(.,simulated_0_slope_l_w,by="L1") %>% group_by(L1) %>% summarize("p-value, no relationship" = (sum(value > max(ts))/100))
summary_simulation_l_w_table <- median_observed_slope_l_w %>% rename("test statistic" = value) %>% select(L1,"test statistic") %>% 
	left_join(.,p_value_slope_1_l_w,by="L1") %>% 
	left_join(.,p_value_slope_0_l_w,by="L1") %>% 
	arrange(match(L1,group_levels))
row.names(summary_simulation_l_w_table) <- summary_simulation_l_w_table$L1
summary_simulation_l_w_table <- summary_simulation_l_w_table %>% select(-L1)

print(xtable(summary_simulation_l_w_table),file="bootstrap_l_w_latex.txt")


### RAINFORD BACKBONE SUMMARY TABLE

load(paste(results_directory,"egg_analysis_rainford_development_workspace.Rdata",sep="/"))

rainback_development <- rbind(round(allometry_vol_Da_hatch_table,2),
	round(allometry_vol_Da_int_btw_preblast_mitoses_table,2),
	round(allometry_vol_Da_time_midcellularization,2)) %>% 
	mutate("p-value" = paste(pval_min,pval_max,sep=" - "),
		"intercept" = paste(int_min,int_max,sep=" - "),
		"slope" = paste(slope_min,slope_max,sep=" - "),
		"sample size" = round(sample_size,0)) %>% 		
	select("p-value","slope","intercept","sample size") %>% mutate(analysis = c("egg volume vs duration of embryogenesis","egg volume vs interval between pre-blastoderm mitoses","egg volume vs time to cellularization"),clade = "Hexapoda")

load(paste(results_directory,"egg_analysis_rainford_allometry_workspace.Rdata",sep="/"))

rainback_l_w <- read_pgls_results(allometry_l_w_table,allometry_group_l_w_table,group_list) %>% mutate(clade = row.names(.),analysis = "egg length vs width")
rainback_l_asym_w <- read_pgls_results(allometry_l_asym_w_table,allometry_group_l_asym_w_table,group_list)%>% mutate(clade = row.names(.),analysis = "egg length vs asymmetry, residuals to egg width")
rainback_l_curv_w <- read_pgls_results(allometry_l_curv_w_table,allometry_group_l_curv_w_table,group_list) %>% mutate(clade = row.names(.),analysis = "egg length vs angle of curvature, residuals to egg width")

load(paste(results_directory,"egg_analysis_rainford_genome_size_egg_size_workspace.Rdata",sep="/"))

rainback_genome_vol	<- round(genome_vol_table,2) %>% mutate("p-value" = paste(pval_min,pval_max,sep=" - "),
		"intercept" = paste(int_min,int_max,sep=" - "),
		"slope" = paste(slope_min,slope_max,sep=" - "),
		"sample size" = round(sample_size,0),
		"clade" = "Hexapoda",
		"analysis" = "genome c-value vs egg volume") %>% 		
		select("p-value","slope","intercept","sample size","clade","analysis")

summary_rainback <- rbind(rainback_development,rainback_genome_vol,rainback_l_w,rainback_l_asym_w,rainback_l_curv_w) %>% select(analysis,clade,"p-value",slope,"sample size")

summary_misoback <- rbind(summary_development %>% 
		mutate(analysis = c("egg volume vs duration of embryogenesis",
			"egg volume vs interval between pre-blastoderm mitoses",
			"egg volume vs time to cellularization"),
				clade = "Hexapoda"),
	summary_genome_vol %>% filter(clade == "Hexapoda") %>% mutate(analysis = "genome c-value vs egg volume"),
	summary_l_w,summary_l_asym_w,summary_l_curv_w) %>% 
		select(analysis,clade,"p-value",slope,"sample size")

combined_backbone_summary <- left_join(summary_rainback %>% 
		rename("Rain. p-value" = "p-value", "Rain. slope" = "slope") %>% 
		select(-"sample size"), 
	summary_misoback %>% 
		rename("Misof p-value" = "p-value", "Misof slope" = "slope"), by = c("analysis", "clade"))

print(xtable(combined_backbone_summary,digits=0),include.rownames=F,file="summary_rainford_backbone_latex.txt")

#### CORBLOMBERG SUMMARY TABLE
load(paste(results_directory,"egg_analysis_corBlomberg_development_workspace.Rdata",sep="/"))

corblom_development <- rbind(round(allometry_vol_Da_hatch_table,2),
	round(allometry_vol_Da_int_btw_preblast_mitoses_table,2),
	round(allometry_vol_Da_time_midcellularization,2)) %>% 
	mutate("p-value" = paste(pval_min,pval_max,sep=" - "),
		"intercept" = paste(int_min,int_max,sep=" - "),
		"slope" = paste(slope_min,slope_max,sep=" - "),
		"sample size" = round(sample_size,0)) %>% 		
	select("p-value","slope","intercept","sample size") %>% mutate(analysis = c("egg volume vs duration of embryogenesis","egg volume vs interval between pre-blastoderm mitoses","egg volume vs time to cellularization"),clade = "Hexapoda")

load(paste(results_directory,"egg_analysis_corBlomberg_allometry_workspace.Rdata",sep="/"))

corblom_l_w <- read_pgls_results(allometry_l_w_table,allometry_group_l_w_table,group_list) %>% mutate(clade = row.names(.),analysis = "egg length vs width")
corblom_l_asym_w <- read_pgls_results(allometry_l_asym_w_table,allometry_group_l_asym_w_table,group_list)%>% mutate(clade = row.names(.),analysis = "egg length vs asymmetry, residuals to egg width")
corblom_l_curv_w <- read_pgls_results(allometry_l_curv_w_table,allometry_group_l_curv_w_table,group_list) %>% mutate(clade = row.names(.),analysis = "egg length vs angle of curvature, residuals to egg width")
corblom_l_w_body <- read_pgls_results(allometry_l_w_body_table,allometry_group_l_w_body_table,group_list) %>% mutate(clade = row.names(.),analysis = "egg length vs width, residuals to body size")
corblom_vol_body <- read_pgls_results(allometry_vol_body_table,allometry_group_vol_body_table,group_list) %>% mutate(clade = row.names(.),analysis = "egg volume vs cubic body length")

load(paste(results_directory,"egg_analysis_corBlomberg_genome_size_egg_size_workspace.Rdata",sep="/"))

corblom_genome_vol	<- round(genome_vol_table,2) %>% mutate("p-value" = paste(pval_min,pval_max,sep=" - "),
		"intercept" = paste(int_min,int_max,sep=" - "),
		"slope" = paste(slope_min,slope_max,sep=" - "),
		"sample size" = round(sample_size,0),
		"clade" = "Hexapoda",
		"analysis" = "genome c-value vs egg volume") %>% 		
		select("p-value","slope","intercept","sample size","clade","analysis")

summary_corblom <- rbind(corblom_development,corblom_genome_vol,corblom_l_w,corblom_l_asym_w,corblom_l_curv_w,corblom_l_w_body,corblom_vol_body) %>% select(analysis,clade,"p-value",slope,"sample size")

summary_corbrow <- rbind(summary_development %>% 
	mutate(analysis = c("egg volume vs duration of embryogenesis",
		"egg volume vs interval between pre-blastoderm mitoses",
		"egg volume vs time to cellularization"),
	clade = "Hexapoda"),
	summary_genome_vol %>% filter(clade == "Hexapoda") %>% mutate(analysis = "genome c-value vs egg volume"),
	summary_l_w,summary_l_asym_w,summary_l_curv_w,summary_l_w_body,summary_vol_body) %>% 
	select(analysis,clade,"p-value",slope,"sample size")

combined_corblom_summary <- left_join(summary_corblom %>% 
		rename("Blom. p-value" = "p-value", "Blom. slope" = "slope") %>% 
		select(-"sample size"),
	summary_corbrow %>% 
		rename("Brown, p-value" = "p-value", "Brown. slope" = "slope"), by = c("analysis","clade"))

print(xtable(combined_corblom_summary,digits=0),include.rownames=F,file="summary_corblom_latex.txt")


### OUWIE
source("analyze_data/egg_analysis_read_ouwie_results.R")

make_ouwie_table <- function(eco_state) {
	summary_misof_mcc_results <- main_results %>% 
		filter(grepl(eco_state,analysis)) %>% 
		mutate(trait = trait_names) %>% 
		select(trait,OUM_best_freq,avg_BM1_OUM_delta,avg_OU1_OUM_delta) %>% 
		rename("freq. OUM best fit" = OUM_best_freq,
			"ave. \\Delta AICc, OUM vs BM1" = avg_BM1_OUM_delta,
			"ave. \\Delta AICc, OUM vs OU1" = avg_OU1_OUM_delta)
	return(summary_misof_mcc_results)
}

trait_names <- c("volume","aspect ratio","asymmetry","angle of curvature") 
print(xtable(make_ouwie_table("internal"),digits=c(0,0,2,2,2)),file="ouwie_internal_latex.txt",include.rownames=F)
print(xtable(make_ouwie_table("in_water"),digits=c(0,0,2,2,2)),file="ouwie_in_water_latex.txt",include.rownames=F)
print(xtable(make_ouwie_table("migratory_Lepidoptera"),digits=c(0,0,2,2,2)),file="ouwie_migratory_Lepidoptera_latex.txt",include.rownames=F)
print(xtable(make_ouwie_table("wingless_Phasmatodea"),digits=c(0,0,2,2,2)),file="ouwie_wingless_Phasmatodea_latex.txt",include.rownames=F)
		
summary_ouwie_simulated_results <- rbind(simulated_internal_results %>% mutate(ecology = "internal"),
									simulated_in_water_results %>% mutate(ecology = "in water")) %>% 
					mutate(trait = c("volume","volume","asymmetry","asymmetry",
									"volume","volume","aspect ratio","aspect ratio"),
							data = rep(c("observed","simulated"),4)) %>% 
					select(ecology,trait,data,OUM_best_freq,BM1_boot_pval,OU1_boot_pval,joint_pval) %>% 
					rename("freq. OUM best fit" = OUM_best_freq,
						"p-value, BM1" = BM1_boot_pval,
						"p-value, OU1" = OU1_boot_pval,
						"joint p-value" = joint_pval)		

print(xtable(summary_ouwie_simulated_results,digits=c(0,0,0,0,2,2,2,2)),file="ouwie_simulated_latex.txt",include.rownames=F)
		
summary_ouwie_mcc_results <- tibble("Misof\ backbone, MCC" = misof_mcc_results$OUM_best,
	"Rainford\ backbone, MCC" = rainford_mcc_results$OUM_best,
	"strict\ classification\ method" = strict_results$OUM_best,
	"broader\ ecological\ definitions" = eco_definition_results$OUM_best)
row.names(summary_ouwie_mcc_results) <- c("internal oviposition, volume",
	"aquatic oviposition, volume",
	"internal oviposition, aspect ratio",
	"aquatic oviposition, aspect ratio",
	"internal oviposition, asymmetry",
	"aquatic oviposition, asymmetry",
	"internal oviposition, angle of curvature",
	"aquatic oviposition, angle of curvature")
print(xtable(summary_ouwie_mcc_results),file="ouwie_mcc_latex.txt")




















