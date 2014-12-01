use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %conf = (
    'NAME'          => 'Algorithm::Diff',
    'VERSION_FROM'  => 'lib/Algorithm/Diff.pm', # finds $VERSION
);

if (eval { ExtUtils::MakeMaker->VERSION(6.3002) }) {
    $conf{LICENSE} = 'perl';
}


if (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    $conf{META_MERGE} = {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type       => 'git',
                url        => 'https://github.com/TyeMcQueen/perl-algorithm-diff.git',
                web        => 'https://github.com/TyeMcQueen/perl-algorithm-diff',
                license    => 'http://dev.perl.org/licenses/',
            },
            #bugtracker => {
            #    web        => 'http://github.com/szabgab/Module-Name/issues',
            #},
            #homepage   => 'http://perlmaven.com/',
        },
        #x_contributors => [
        #    'Peti Bar <petibar@cpan.org>',
        #],
        #x_IRC => 'irc://irc.perl.org/#perl',
        #x_MailingList => 'http://lists.perl.org/list/perl-qa.html',
    };
}

WriteMakefile(%conf);

