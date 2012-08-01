#!/usr/bin/Rscript

## This R script is useful to inspect the table that is put out by the check-tools-integrity.py script, with the aim of filtering the original CLARIN tools registry CSV
## for stale/irrelevant/problematic records.

tools_registry 		<- read.csv("/tmp/export_tools", header = TRUE);
checks_output_table <- read.table("/tmp/output.tab", sep = '\t', check.names = FALSE, header = TRUE);

records_to_be_kept 	<- subset(output_table, `Reference link (field_tool_reference_link)` != "unspecified");
## Records whose contact person should be warned because the "Reference link" URL value is problematic.
records_problematic <- subset(records_to_be_kept, `Reference link (field_tool_reference_link)` == "problematic");

URLs 				<- tools_registry[row.names(records_problematic),17]

## To inspect the problematic records manually:
edit(records_problematic)

## Bar plot of frequencies of problematic Reference link values by country.
plot(factor(tools_registry[row.names(records_problematic),10]))
