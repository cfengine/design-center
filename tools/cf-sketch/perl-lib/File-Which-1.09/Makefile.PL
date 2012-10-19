use 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'         => 'File::Which',
	'ABSTRACT'     => 'Portable implementation of the "which" utility',
	'VERSION_FROM' => 'lib/File/Which.pm',
	'PREREQ_PM'    => {
		'Exporter'     => 0,
		'Getopt::Std'  => 0,
		'File::Spec'   => '0.60',
		'Test::More'   => '0.80',
		'Test::Script' => '1.05',
	},
	'EXE_FILES' => [
		'script/pwhich',
	],
	( $] >= 5.005 ? (
		AUTHOR => 'Adam Kennedy <adamk@cpan.org>',
	) : () ),
	( $ExtUtils::MakeMaker::VERSION ge '6.31' ? (
		LICENSE => 'perl',
	) : () ),
);
