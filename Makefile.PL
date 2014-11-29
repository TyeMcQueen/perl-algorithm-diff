use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME => 'Algorithm::LCS',
	      VERSION => '0.53',
#	      'linkext' => {LINKTYPE => ''},
	      'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);
