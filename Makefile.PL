use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME => 'Algorithm::Diff',
	      VERSION => '0.54',
#	      'linkext' => {LINKTYPE => ''},
	      'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);
