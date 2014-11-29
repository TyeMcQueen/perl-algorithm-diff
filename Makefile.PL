use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME => 'Algorithm::Diff',
	      VERSION => '0.59',
#	      'linkext' => {LINKTYPE => ''},
	      'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);
