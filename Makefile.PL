use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME => 'Algorithm::Diff',
	      VERSION => '0.57',
#	      'linkext' => {LINKTYPE => ''},
	      'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);
