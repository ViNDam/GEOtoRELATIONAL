#Title:		Convert GEO data to relational tables
#Author: 	Vi Dam
#Date:		Apr 2018

#---------------------------------READ ME----------------------------------
#This program requires: 
#	datamash installation
#	GSE series list
#This program works on MAC Terminal only
#--------------------------------------------------------------------------

seriesList="GSEList"

#-------DOWNLOAD soft files, series matrix files, xml.tgz files
for series in `cut -f 1 -d "	" $seriesList` ; do 
	FtTwo=$(echo $series|cut -c1-5);
	#soft
	wget ftp://ftp.ncbi.nlm.nih.gov/geo/series/"$FtTwo"nnn/$series/soft/"$series"_family.soft.gz;
	#series matrix
	wget ftp://ftp.ncbi.nlm.nih.gov/geo/series/"$FtTwo"nnn/$series/matrix/"$series"*_series_matrix.txt.gz;
	#family.xml.tgz
	wget ftp://ftp.ncbi.nlm.nih.gov/geo/series/"$FtTwo"nnn/$series/miniml/"$series"*.tgz;

	#-------TAR the zipped files----------------------
	tar -xzvf "$series"*family.xml.tgz;
	gunzip "$series"*family.soft.gz;
	gunzip "$series"*_series_matrix.txt.gz;
done;

#-------
softFiles=`ls *.soft`
#matrixFiles=$(ls *series_matrix.txt)
#ontologyPlatforms=$(ls GPL*.txt)

#--------------------------------------------SERIES
for softFile in $softFiles;do
	
	seriesAccession=$(cat $softFile|grep "Series_geo_accession"|sed 's/!Series_geo_accession = //');
	matrixFiles="$seriesAccession"*series_matrix.txt;

	#collect data and print to Series file
	Title=$(cat $softFile |grep "Series_"|grep -E "_title"|cut -f 2 -d "="|sed 's/^ //g'|tr '\n' ' ' );
        Geo_accession=$(cat $softFile |grep "Series_"|grep -E "_geo_accession"|cut -f 2 -d "="|sed 's/^ //g'|tr '\n' ' ' );
        Status=$(cat $softFile |grep "Series_"|grep -E "_status"|cut -f 2 -d "="|sed 's/^ //g'|tr '\n' ' ' );
        Submission_date=$(cat $softFile |grep "Series_"|grep -E "_submission_date"|cut -f 2 -d "="|sed 's/^ //g'|tr '\n' ' ' );
        Pubmed_id=$(echo `cat $softFile |grep "Series_"|grep "_pubmed_id"`|sed 's/\!Series_pubmed_id = //g'|tr '\n' ' ' );
        Series_summary=$(echo `cat $softFile |grep "Series_summary"`|sed 's/\!Series_summary = //g'|tr '\n' ' ' );
        Series_overall_design=$(echo `cat $softFile |grep "Series_overall_design"`|sed 's/\!Series_overall_design = //g'|tr '\n' ' ' );
        Series_type=$(echo `cat $softFile |grep "Series_type"`|sed 's/\!Series_type = //g'|tr '\n' ' ' );
        Series_supplementary_file=$(echo `cat $softFile |grep "Series_supplementary_file"`|sed 's/\!Series_supplementary_file = //g'|tr '\n' ' ' );
        echo "$Title	$Geo_accession	$Status	$Submission_date	$Pubmed_id	$Series_summary	$Series_overall_design	$Series_type	$Series_supplementary_file" >> Series.csv;


#--------------------------------------------PLATFORMS
#--------------------------------------------SERIES_PLATFORMS
#for softFile in $softFiles;do

	Platform_title=$(echo `cat $softFile|grep "Platform_title"`|cut -f 2 -d "="|sed 's/^ //g'|tr '\n' '  ');
	Platform_geo_accession=$(echo `cat $softFile|grep "Platform_geo_accession"`|cut -f 2 -d "="|sed 's/^ //g'|tr '\n' '  ');
	Platform_technology=$(echo `cat $softFile|grep "Platform_technology"`|cut -f 2 -d "="|sed 's/^ //g'|tr '\n' '  ');
	Platform_distribution=$(echo `cat $softFile|grep "Platform_distribution"`|cut -f 2 -d "="|sed 's/^ //g'|tr '\n' '  ');
	Platform_organism=$(echo `cat $softFile|grep "Platform_organism"`|cut -f 2 -d "="|sed 's/^ //g'|tr '\n' '  ');
	Platform_taxid=$(echo `cat $softFile|grep "Platform_taxid"`|cut -f 2 -d "="|sed 's/^ //g'|tr '\n' '  ');
	Platform_manufacturer=$(echo `cat $softFile|grep "Platform_manufacturer"`|cut -f 2 -d "="|sed 's/^ //g'|tr '\n' '  ');

	echo "$Platform_title	$Platform_geo_accession	$Platform_technology	$Platform_distribution	$Platform_organism	$Platform_taxid	$Platform_manufacturer" >> Platforms.csv;
	
	platformsID=$(cat $softFile|grep "Platform_geo_accession"|cut -f 3 -d " "|tr '\n' ' ' );
	for plf in $platformsID; do 
		echo "$seriesAccession	$plf" >>Series_Platforms.csv ;
	done;

#--------------------------------------------CONTRIBUTOR (First, Middle,Last Name)
#--------------------------------------------SERIES_CONTRIBUTORS (seriesAccession, CtrbtID)----
	contributorNumber=`cat Contributors.csv|wc -l`;
	nextLine=`expr $contributorNumber + 1`;
	newContributorsNumber=`cat $softFile |grep "Series_contributor"|wc -l`;
	lastLine=`expr $nextLine + $newContributorsNumber `;

	cat $softFile |grep "Series_contributor"|cut -f 3 -d " "|sed 's/,/	/g' >> Contributors.csv;
	
	#add the CtrbtID number to the beginning of new printed lines in Contributors file
	for i in `seq $nextLine $lastLine`; do 
		sed -i "" "${i}s/^/Ctrbt$i	/" Contributors.csv;
	done;

	lastLine=`expr $lastLine - 1`;
	for i in `seq $nextLine $lastLine`; do
		echo "$seriesAccession	Ctrbt$i" >> Series_Contributors.csv;
	done;

#--------------------------------------------SAMPLES
#--------------------------------------------SERIES_SAMPLES
	for matrixFile in $matrixFiles;do
		#cat $matrixFile|grep "\!Sample_"|sed 's/!Sample_/Sample_/g'|cut -f 2- -d "	"|datamash --no-strict transpose|sed 's/"//g' >> Samples.csv;
		cat $matrixFile|grep -E "Sample_title|Sample_geo_accession|Sample_status|Sample_submission_date|Sample_last_update_date|Sample_type|Sample_channel_count|Sample_source_name_ch1|Sample_organism_ch1|Sample_molecule_ch1|Sample_label_ch1|Sample_label_protocol_ch1|Sample_taxid_ch1|Sample_hyb_protocol|Sample_scan_protocol|Sample_platform_id|Sample_supplementary_file|Sample_data_row_count"|sed 's/!Sample_/Sample_/g'|cut -f 2- -d "	"|datamash --no-strict transpose|sed 's/"//g' >> Samples.csv;

		samples=$(cat $softFile|grep "Sample_geo_accession"|cut -f 3 -d " "); 
		for s in $samples;do
			echo "$seriesAccession	$s" >> Series_Samples.csv;
		done;
		
		#--------------------------------------------GENE EXPRESSION
		
		for s in $samples;do 
			awk -v OFS='\t' '{print $0, sampleName}' sampleName=$s $s-tbl*.txt;
		done >> GeneExpression.csv;
	done;
done;

#--------------------------------------------ONTOLOGY
platformsID="GSE72099";
sed -e '1,/platform_table_begin/d' -e '/platform_table_end/,$d' "$platformsID"_family.soft|sed '/Entrez_Gene_ID/d' > Ontology.csv;

#to get pattern multiple times
#sed -n '/platform_table_begin/,/platform_table_end/p' "$platformsID"_family.soft|sed '/platform_table_begin/d'|sed '/platform_table_end/d'|sed '/Entrez_Gene_ID/d' > Ontology.csv;

#add seriesID to first column
ontologyNumber=`cat Ontology.csv|wc -l`;
ontologyNumber=`expr $ontologyNumber - 1`;
for l in `seq 1 $ontologyNumber`;do
	sed -i "" "${l}s/^/$platformsID	/" Ontology.csv;
done;
#for plf in $platformsID;do
	#paste "$plf"*.txt >> Ontology.csv;
#done;
#----------------------------------------------------
#-----------------------------------------------
#surround data with "" to insert into sql database
sed -i '' 's/[^	]*/"&"/g' Samples.csv;
sed -i '' 's/[^	]*/"&"/g' Series.csv;
sed -i '' 's/[^	]*/"&"/g' Platforms.csv;
sed -i '' 's/[^	]*/"&"/g' Series_Platforms.csv;
sed -i '' 's/[^	]*/"&"/g' Contributors.csv;
sed -i '' 's/[^	]*/"&"/g' Series_Contributors.csv;
sed -i '' 's/[^	]*/"&"/g' Ontology.csv;
sed -i '' 's/[^	]*/"&"/g' Series_Samples.csv;
sed -i '' 's/[^	]*/"&"/g' GeneExpression.csv;

#add header to files
awk 'BEGIN{print"Title	Series_geo_accession	Status	Submission_date	Pubmed_id	Series_summary	Series_overall_design	Series_type	Series_supplementary_file"}1' Series.csv >tmp && mv tmp Series.csv;

awk 'BEGIN{print"Platform_title	Platform_geo_accession	Platform_technology	Platform_distribution	Platform_organism	Platform_taxid	Platform_manufacturer"}1' Platforms.csv >tmp && mv tmp Platforms.csv;

awk 'BEGIN{print"Series_geo_accession	Platform_geo_accession"}1' Series_Platforms.csv >tmp && mv tmp Series_Platforms.csv;

awk 'BEGIN{print"Contributor_ID	Contributor_FirstName	Contributor_MiddleName	Contributor_LastName"}1' Contributors.csv >tmp && mv tmp Contributors.csv;

awk 'BEGIN{print"Series_geo_accession	Contributor_ID"}1' Series_Contributors.csv >tmp && mv tmp Series_Contributors.csv;

awk 'BEGIN{print"Series_geo_accession	Gene_ID	Species	Source	Search_Key	Transcript	ILMN_Gene	Source_Reference_ID	RefSeq_ID	Unigene_ID	Entrez_Gene_ID	GI	Accession	Symbol	Protein_Product	Array_Address_Id	Probe_Type	Probe_Start	SEQUENCE	Chromosome	Probe_Chr_Orientation	Probe_Coordinates	Cytoband	Definition	Ontology_Component	Ontology_Process	Ontology_Function	Synonyms	GB_ACC"}1' Ontology.csv >tmp && mv tmp Ontology.csv;

awk 'BEGIN{print"Title	SampleID	Status	Submission_date	Last_update_date	Type	Channel_count	Source_name_ch1	Organism_ch1	Molecule_ch1	Label_ch1	Label_protocol_ch1	Taxid_ch1	Hyb_protocol	Scan_protocol	Platform_id	Supplementary_file	Data_row_count"}1' Samples.csv >tmp && mv tmp Samples.csv;

awk 'BEGIN{print"Series_geo_accession	SampleID"}1' Series_Samples.csv >tmp && mv tmp Series_Samples.csv;

awk 'BEGIN{print"Gene_ID	Value	Sample"}1' GeneExpression.csv >tmp && mv tmp GeneExpression.csv;


#make INSERT sql files from csv files
tablesList="Series.csv GeneExpression.csv Platforms.csv Ontology.csv Samples.csv Contributors.csv Series_Samples.csv Series_Platforms.csv Series_Contributors.csv"
for table in $tablesList; do
	cp $table $table.sql;
	tableName=`echo $table|sed 's/.csv//g'`
	sed -i '' '1d' $table.sql;
	sed -i '' "s/^/INSERT INTO $tableName VALUES (/g" $table.sql;
	sed -i '' 's/	/,/g' $table.sql;
	sed -i '' 's/$/);/g' $table.sql;
done;

#remove all download files for less memory
rm *.soft *gz *.txt *.xml


#awk 'NR=1' Series.csv|while IFS='' read -r line;do echo INSERT INTO Series VALUES \($line\)\;|sed 's/" "/","/g';done >InsertSeries.sql
#awk 'NR=1' Platforms.csv|while IFS='' read -r line;do echo INSERT INTO Series VALUES \($line\)\;|sed 's/" "/","/g';done >InsertPlatforms.sql
#awk 'NR=1' Contributors.csv|while IFS='' read -r line;do echo INSERT INTO Series VALUES \($line\)\;|sed 's/" "/","/g';done >InsertContributors.sql
#awk 'NR=1' Ontology.csv|while IFS='' read -r line;do echo INSERT INTO Series VALUES \($line\)\;|sed 's/" "/","/g';done >InsertOntology.sql
#awk 'NR=1' Samples.csv|while IFS='' read -r line;do echo INSERT INTO Series VALUES \($line\)\;|sed 's/" "/","/g';done >InsertSamples.sql
#awk 'NR=1' Series_Samples.csv|while IFS='' read -r line;do echo INSERT INTO Series VALUES \($line\)\;|sed 's/" "/","/g';done >InsertSeries_Samples.sql
#awk 'NR=1' Ontology.csv|while IFS='' read -r line;do echo INSERT INTO Series VALUES \($line\)\;|sed 's/" "/","/g';done >InsertOntology.sql
#awk 'NR=1' Series_Platforms.csv|while IFS='' read -r line;do echo INSERT INTO Series VALUES \($line\)\;|sed 's/" "/","/g';done >InsertSeries_Platforms.sql
#awk 'NR=1' Series_Contributors.csv|while IFS='' read -r line;do echo INSERT INTO Series VALUES \($line\)\;|sed 's/" "/","/g';done >InsertSeries_Contributors.sql



