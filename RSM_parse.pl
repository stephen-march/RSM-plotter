#!/usr/bin/perl
# need the line above for Windows file systems. not needed for unix systems

use warnings;
use strict;

####################################################################################################################
#                                       === Script Notes === 	                                                   #
####################################################################################################################
system("cls"); # clears command line screen
if(($ARGV[0] =~ /-h/i) or ($ARGV[0] =~ /-help/i)){
print "# \n";
print "# RSM_parse.pl\n";
print "# \n";
print "# Parses through .txt files exported from Rigaku 3D Explore software.\n";
print "# It takes the wavelength and the omega-two theta for the substrate to calculate the absolute Qx and Qz \n";
print "# The conversion to absolute from relative using these parameters is done outside this program, e.g. RSM_plot.m\n";
print "# \n";
print "# The user must provide the input file in order to run this script\n";
print "# For example:   perl RSM_parse.pl \"my_values.txt\"";
print "# \n";
print "# === Output files generated ===\n";
print "#   	RSM_parse_output.csv 	-->	Has the relative Qx, Qz, and intensity values, in that order \n";
print "#   	RSM_parse_output_params.csv 	-->	Has the x-ray wavelength (angstroms), omega, and two-theta for the substrate \n";
print "#\n";
die "help command was activated";
}

####################################################################################################################
#                                       === Code Body === 	                                                       #
####################################################################################################################

open(RSMoutput, ">RSM_plot_output.csv");									# output file 
open(RSMoutputparams, ">RSM_plot_output_params.csv");						# output file
open(debug, ">RSM_parse_debug.txt");

# initialize variables that will be used only once later
my $wavelength = 0;
my $omega = 999;
my $twoTheta = 999;
my $tripOnlyData = 0;
my $onlyData = 0;

# clears command line screen in Windows
system("cls"); 
# system("clear"); #clears the command line in unix

my $RSM_input = $ARGV[0];		# input file from command line. In Windows, run as ><dir>\ perl flux_log_aggregator.pl "<input_file_name>"
if (not defined $RSM_input) {
  warn "No input file provided!\n";
  warn "See example in this script's notes and RSM_parse.pl documentation\n";
}


# Open the RSM file to plot
#my $filename = "C:\Users\stephen\Desktop\RSM_plot_Rigaku\testing\RSM_example.txt";
# my $filename = "RSM_example.txt"; # manually pick the file name
my $filename = $RSM_input;
open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";

# Regex patterns for parsing through the different lines
# See https://regex101.com/ for help and future testing
my $reWavelength = qr/\# wavelength: (\d+\.\d+)/; # '# wavelength: 1.540593'
my $reOrigin = qr/\# gonio origin : (\d+\.\d+)\s+(\d+\.\d+)\s+\d+\.\d+\s+\d+\.\d+/; # '# gonio origin : 40.014600 80.029200 0.000000 0.000000' 
my $reData1 = qr/(\-\d+\.\d+)\s+(\d+\.\d+)\s+(\-\d+\.\d+)/;							#-0.0214577	0.7118884	-1.0000
my $reData2 = qr/(\d+\.\d+)\s+(\d+\.\d+)\s+(\-\d+\.\d+)/;							#0.0214577	0.7118884	-1.0000
my $reData3 = qr/(\-\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)/;							#-0.0214577	0.7118884	1.0000
my $reData4 = qr/(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)/;								#0.0214577	0.7118884	1.0000
my $reData5 = qr/^(?!#).*$/;														## followed by any set of characters, that is ignore any string that starts with '#'


while (my $line = <$fh>) {														# reads through each line of the file

	chomp($line);																# segments the file based on white space

	# DEBUG LINE
	# print "$line\n";

		if ($line =~ $reWavelength){
			$wavelength = $1;													# collect element symbol
			print "wavelength: $wavelength\n";
		}
		
		if ($line =~ $reOrigin){
			$omega = $1;														# collect element symbol
			$twoTheta = $2;
			print "omega: $omega\ttwo theta: $twoTheta\n";
			
			#$tripOnlyData = 1;
		}			

		if ( ($line =~ $reData5) and (($line =~ $reData1) or ($line =~ $reData2) or ($line =~ $reData3) or ($line =~ $reData4))){
		#if ( ($onlyData == 1) and (($line =~ $reData1) or ($line =~ $reData2) or ($line =~ $reData3) or ($line =~ $reData4))){
			
			my $Qx = $1;														# collect element symbol
			my $Qz = $2;
			my $intensity = $3;
			#print "=\n";
			#print "Qx: $Qx\tQz: $Qz\tintensity: $intensity\n";
			
			# DEBUG
			# if ($line =~ $reData5){
			# print debug "$Qx,$Qz,$intensity\n";
			# }
			
			# offset all intensity values to make sure they are all at least +1
			my $offset = 2;		# some values are negative 1 due to the detector, so shift by +2 for log10 plotting			
			my $newIntensity = $intensity + $offset;
			print RSMoutput "$Qx,$Qz,$newIntensity\n";
			print debug "$Qx,$Qz,$newIntensity\n";
			#print "Qx: $Qx\tQz: $Qz\toffset intensity: $newIntensity\n";
		}

		#if ($tripOnlyData == 1){
		#	$onlyData = 1;
		#}
	
}

# print output params
print RSMoutputparams "$wavelength\n$omega\n$twoTheta\n";

# close output files
close(RSMoutput);
close(RSMoutputparams);