#!/usr/bin/Rscript

## This R script is useful to inspect the table that is put out by the check-tools-integrity.py script, with the aim of filtering the original CLARIN tools registry CSV
## for stale/irrelevant/problematic records.

tools_registry <- 
	read.csv("/tmp/export_tools", 
			 check.names = FALSE, 
			 header = TRUE);
checks_output_table <- 
	read.table("/tmp/output.tab", 
			   sep = '\t', 
			   check.names = FALSE, 
			   header = TRUE);

colnames(checks_output_table) <- 
	paste(colnames(checks_output_table), "check");

tools_registry <- 
	tools_registry[, -1 * which(colnames(tools_registry) == "URL check result (field_tool_urlcheck)")];

records_to_be_kept <- 
	subset(checks_output_table, 
			`Reference link (field_tool_reference_link) check` != "unspecified");




## Records whose contact person should be warned.
records_any_unspecified <- 
	subset(records_to_be_kept, `Reference link (field_tool_reference_link) check` 			== "unspecified" 
								| `Documentation link (field_tool_document_link) check` 	== "unspecified" 
								| `Webservice link (field_tool_webservice_link) check`		== "unspecified");


complete_extended_table <- 
	cbind(tools_registry, checks_output_table);

write.table(complete_extended_table, 
				file 		= "/tmp/export_tools__complete_extended__7-8-2012.csv", 
				sep 		= ',', 
				row.names 	= FALSE, 
				col.names 	= TRUE);


records_relevant_links_specified <- 
	subset(records_to_be_kept, (`Reference link (field_tool_reference_link) check` 	    != "unspecified"
								| `Webservice link (field_tool_webservice_link) check` 	!= "unspecified") 
							& `Documentation link (field_tool_document_link) check` 	!= "unspecified");
links_specified_table <- 
	cbind(tools_registry[row.names(records_relevant_links_specified),], records_relevant_links_specified);

write.table(links_specified_table, 
			file 			= "/tmp/export_tools__relevant_links_specified__7-8-2012.csv", 
			sep 			= ',', 
			row.names 		= FALSE, 
			col.names 		= TRUE);


records_relevant_links_work <- 
	subset(records_to_be_kept, (`Reference link (field_tool_reference_link) check`  == "works"
							| `Webservice link (field_tool_webservice_link) check` 	== "works") 
							& `Documentation link (field_tool_document_link) check` == "works");
links_work_table <- 
	cbind(tools_registry[row.names(records_relevant_links_work),], records_relevant_links_work);

write.table(links_work_table, 
			file 			= "/tmp/export_tools__relevant_links_work__7-8-2012.csv", 
			sep 			= ',', 
			row.names 		= FALSE, 
			col.names 		= TRUE);

URLs <-
	tools_registry[row.names(records_problematic),17];

## To inspect the problematic records manually:
edit(records_problematic);

## Bar plot of frequencies of problematic Reference link values by country.
plot(factor(tools_registry[row.names(records_problematic),10]));
