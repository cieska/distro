package AddressTests;
use strict;
use warnings;

use FoswikiTestCase;
our @ISA = qw( FoswikiTestCase );

use Assert;
use Data::Dumper;
use Benchmark qw(:hireswallclock);
use Foswiki::Address();
use constant TRACE => 0;

my $FoswikiSESSION;
my $test_web  = 'Temporary' . __PACKAGE__ . 'TestWeb';
my %testrange = (
    webs => [
        [$test_web],
        [ 'Missing' . $test_web ],
        [ $test_web,             'SubWeb' ],
        [ $test_web,             'MissingSubWeb' ],
        [ 'Missing' . $test_web, 'MissingSubWeb' ],
        [ $test_web,             'SubWeb',        'SubSubWeb' ],
        [ $test_web,             'SubWeb',        'MissingSubSubWeb' ],
        [ $test_web,             'MissingSubWeb', 'MissingSubSubWeb' ],
        [ 'Missing' . $test_web, 'MissingSubWeb', 'MissingSubSubWeb' ]
    ],
    topics => [ undef, 'Topic', 'MissingTopic' ],
    parts  => {
        undef => [undef],
        FILE  => [
            undef,               'Attachment',
            'Attach.ent',        'Atta.h.ent',
            'MissingAttachment', 'MissingAttach.ent',
            'MissingAtta.h.ent'
        ],
        SECTION => [ undef, [ { name => 'something' } ] ],
        META => [
            undef,
            ['FIELD'],
            [ 'FIELD', { name => 'Colour' } ],
            [ 'FIELD', { name => 'Colour' }, 'value' ],
            [ 'FIELD', { name => 'Colour', form => 'MyForm' } ],
            [ 'FIELD', { name => 'Colour', form => 'MyForm' }, 'value' ]
        ],
        text => [undef]
    },
    revs            => [ undef, 2 ],
    webseparators   => [ '/',   '.' ],
    topicseparators => [ '/',   '.' ]
);
my %testspec = (
    meta_root => {
        string => "'$test_web.Topic'/META",
        atoms  => { web => $test_web, topic => 'Topic', part => 'META' },
        type   => 'meta'
    },
    meta_info => {
        string => "'$test_web.Topic'/info",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => ['TOPICINFO']
        },
        type => 'metatype'
    },
    meta_topicinfo => {
        string => "'$test_web.Topic'/META:TOPICINFO",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => ['TOPICINFO']
        },
        type => 'metatype'
    },
    meta_info_version => {
        string => "'$test_web.Topic'/info.version",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => [ 'TOPICINFO', undef, 'version' ]
        },
        type => 'metakey'
    },
    meta_topicinfo_version => {
        string => "'$test_web.Topic'/META:TOPICINFO.version",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => [ 'TOPICINFO', undef, 'version' ]
        },
        type => 'metakey'
    },
    meta_field => {
        string => "'$test_web.Topic'/META:FIELD",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => ['FIELD']
        },
        type => 'metatype'
    },
    meta_field_colour => {
        string => "'$test_web.Topic'/META:FIELD[name='Colour']",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => [ 'FIELD', { name => 'Colour' } ]
        },
        type => 'metamember'
    },
    meta_field_3 => {
        string => "'$test_web.Topic'/META:FIELD[3]",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => [ 'FIELD', 3 ]
        },
        type => 'metamember'
    },
    meta_field_colour_value => {
        string => "'$test_web.Topic'/META:FIELD[name='Colour'].value",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => [ 'FIELD', { name => 'Colour' }, 'value' ]
        },
        type => 'metakey'
    },
    meta_field_3_value => {
        string => "'$test_web.Topic'/META:FIELD[3].value",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => [ 'FIELD', 3, 'value' ]
        },
        type => 'metakey'
    },
    meta_fields => {
        string => "'$test_web.Topic'/fields",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => ['FIELD']
        },
        type => 'metatype'
    },
    meta_fields_colour => {
        string => "'$test_web.Topic'/fields[name='Colour']",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => [ 'FIELD', { name => 'Colour' } ]
        },
        type => 'metamember'
    },
    meta_fields_3 => {
        string => "'$test_web.Topic'/fields[3]",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => [ 'FIELD', 3 ]
        },
        type => 'metamember'
    },
    meta_fields_colour_value => {
        string => "'$test_web.Topic'/fields[name='Colour'].value",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => [ 'FIELD', { name => 'Colour' }, 'value' ]
        },
        type => 'metakey'
    },
    meta_fields_3_value => {
        string => "'$test_web.Topic'/fields[3].value",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => [ 'FIELD', 3, 'value' ]
        },
        type => 'metakey'
    },
    meta_myform => {
        string => "'$test_web.Topic'/MyForm",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => [ 'FIELD', { form => 'MyForm' } ]
        },
        type       => 'metatype',
        expectfail => 1
    },
    meta_myform_colour => {
        string => "'$test_web.Topic'/MyForm[name='Colour']",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => [ 'FIELD', { form => 'MyForm', name => 'Colour' } ]
        },
        type => 'metamember'
    },
    meta_myform_colour_value => {
        string => "'$test_web.Topic'/MyForm[name='Colour'].value",
        atoms  => {
            web   => $test_web,
            topic => 'Topic',
            part  => 'META',
            subpart =>
              [ 'FIELD', { form => 'MyForm', name => 'Colour' }, 'value' ]
        },
        type => 'metakey'
    },
    meta_myform_dt_colour => {
        string => "'$test_web.Topic'/MyForm.Colour",
        atoms  => {
            web   => $test_web,
            topic => 'Topic',
            part  => 'META',
            subpart =>
              [ 'FIELD', { form => 'MyForm', name => 'Colour' }, 'value' ]
        },
        type => 'metakey'
    },
    meta_colour => {
        string => "'$test_web.Topic'/Colour",
        atoms  => {
            web     => $test_web,
            topic   => 'Topic',
            part    => 'META',
            subpart => [ 'FIELD', { name => 'Colour' }, 'value' ]
        },
        type => 'metakey'
    }
);
my %rangetestitems;
my %spectestitems;
my $done_init;

sub new {
    my ( $class, @args ) = @_;
    my $this = $class->SUPER::new(@args);

    $this->{test_web}   = $test_web;
    $this->{test_topic} = 'TestTopic' . $class;
    $this->gen_testrange_fns();
    $this->gen_testspec_fns();

    return $this;
}

sub set_up {
    my ($this) = @_;

    # We don't want the overhead of creating a new session for each tests
    if ( not $done_init ) {
        my $query = Unit::Request->new("");
        $this->SUPER::set_up();
        $query->path_info("/$this->{test_web}/$this->{test_topic}");

        #$this->{session}->finish();
        $this->{session} =
          Foswiki->new( $Foswiki::cfg{AdminUserLogin}, $query );

        # SMELL: Why do I need to set this? I don't get our unit tests...
        #$this->{session}->{webName} = $this->{test_web};

        $this->{test_topicObject} = Foswiki::Meta->new(
            $this->{session},    $this->{test_web},
            $this->{test_topic}, "BLEEGLE\n"
        );

        $this->gendata( \%testrange );
        $Foswiki::Plugins::SESSION = $this->{session};
        $FoswikiSESSION            = $this->{session};
        $done_init                 = 1;
    }
    else {
        $this->{session} = $FoswikiSESSION;

        #$Foswiki::Plugins::SESSION = $this->{session};
    }

    return;
}

# We don't want the overhead of creating a new session for each tests, so this
# does nothing.
sub tear_down {
    return;
}

sub gendata {
    my ( $this, $range ) = @_;
    my %created;

    foreach my $webpath ( @{ $range->{webs} } ) {
        if ($webpath) {
            my $web = join( '/', @{$webpath} );

            if ( $web and not $created{webs}{$web} and not $web =~ /Missing/ ) {
                print "gendata(): web $web\n" if TRACE;
                Foswiki::Func::createWeb($web);
                $this->gentopics( $web, $range );
                $created{webs}{$web} = 1;
            }
        }
    }

    return;
}

sub gentopics {
    my ( $this, $web, $range ) = @_;
    my $tmpdir = Foswiki::Func::getWorkArea('UnitTestContrib');

    print "gentopics(): Working on web $web\n" if TRACE;
    foreach my $topic ( @{ $range->{topics} } ) {
        if ( $topic and not $topic =~ /^Missing/ ) {
            my $filedata = "This is file: $web.$topic";

            print "gentopics(): \tWorking on topic $topic\n" if TRACE;
            foreach my $rev ( @{ $range->{revs} } ) {
                if ( defined $rev ) {
                    print "gentopics(): \t\tWorking on rev $rev\n" if TRACE;
                    Foswiki::Func::saveTopic( $web, $topic, undef,
                        <<"HERE", { forcenewrevision => 1 } );
This is topic: $web.$topic @ $rev
HERE
                    foreach my $attachment ( @{ $range->{parts}->{FILE} } ) {
                        if ( defined $attachment
                            and not $attachment =~ /^Missing/ )
                        {
                            my $filepath =
                              File::Spec->catfile(
                                File::Spec->splitdir($tmpdir), $attachment )
                              or die $!;

                            open( my $fh, '>', $filepath )
                              or die "Couldn't open $filepath, '$filedata': $!";
                            print $fh "$filedata/$attachment @ $rev";
                            close($fh);
                            open( $fh, '<', $filepath );
                            print "gentopics(): \t\tattachment $attachment\n"
                              if TRACE;
                            Foswiki::Func::saveAttachment( $web, $topic,
                                $attachment, { stream => $fh } );
                            close($fh);
                        }
                    }
                }
            }
        }
    }

    return;
}

sub test_nothing {
    my ($this) = @_;

    return;
}

sub gen_testrange_fns {
    my ($this) = @_;

    if ( not scalar( keys %rangetestitems ) ) {
        %rangetestitems = ( $this->gen_range_tests( \%testrange ) );
    }
    while ( my ( $testname, $testitem ) = each %rangetestitems ) {
        my $fn = __PACKAGE__ . '::test_' . $testname;
        my %extraopts;

        if ( $testitem->{addrObj}->isA('webs') ) {
            %extraopts = ( existAs => [qw(file topic web)] );
        }
        no strict 'refs';
        *{$fn} = sub {
            my $parsedaddrObj = Foswiki::Address->new(
                string => $testitem->{addrObj}->stringify(),
                %extraopts
            );

            ASSERT( $parsedaddrObj->equiv( $testitem->{addrObj} ) );

            return;
        };
        use strict 'refs';
    }

    return;
}

sub gen_testspec_fns {
    my ($this) = @_;

    if ( not scalar( keys %spectestitems ) ) {
        %spectestitems = ( $this->gen_spec_tests( \%testspec ) );
    }
    while ( my ( $testname, $testitem ) = each %spectestitems ) {
        my $fn = __PACKAGE__ . '::test_' . $testname;
        my %extraopts;

        no strict 'refs';
        *{$fn} = sub {
            my $parsedaddrObj = Foswiki::Address->new(
                string => $testitem->{string},
                %extraopts
            );

            if ( $testitem->{expectfail} ) {
                ASSERT( not $parsedaddrObj->equiv( $testitem->{addrObj} ) );
                ASSERT( $parsedaddrObj->type() ne $testitem->{type} );
            }
            else {
                ASSERT( $parsedaddrObj->equiv( $testitem->{addrObj} ) );
                ASSERT( $parsedaddrObj->type() eq $testitem->{type} );
            }

            return;
        };
        use strict 'refs';
    }

    return;
}

sub list_tests {
    my ( $this, $suite ) = @_;
    my @testnames;

    if ( not scalar( keys %rangetestitems ) ) {
        %rangetestitems = $this->gen_range_tests( \%testrange );
        %spectestitems  = $this->gen_spec_tests( \%testspec );
    }
    foreach my $testname ( keys %rangetestitems, keys %spectestitems ) {
        push( @testnames, __PACKAGE__ . '::test_' . $testname );
    }

    return @testnames, $this->SUPER::list_tests($suite);
}

sub gen_range_tests {
    my ( $this, $range ) = @_;
    my %tests;

    foreach my $webseparator ( @{ $range->{webseparators} } ) {
        foreach my $topicseparator ( @{ $range->{topicseparators} } ) {
            foreach my $webs ( @{ $range->{webs} } ) {
                foreach my $topic ( @{ $range->{topics} } ) {
                    foreach my $part ( keys %{ $range->{parts} } ) {
                        foreach my $subpart ( @{ $range->{parts}->{$part} } ) {
                            foreach my $rev ( @{ $range->{revs} } ) {
                                if (
                                    $webs
                                    and ( $part and $part ne 'FILE'
                                        or ( defined $topic ) )
                                  )
                                {
                                    $part = undef if $part and $part eq 'undef';
                                    my $addrObj = Foswiki::Address->new(
                                        webseparator   => $webseparator,
                                        topicseparator => $topicseparator,
                                        webs           => $webs,
                                        topic          => $topic,
                                        part           => $part,
                                        subpart        => $subpart,
                                        rev            => $rev
                                    );
                                    my $string = $addrObj->stringify();

                                    if ($string) {
                                        my $name = 'range_' . $string;

                                        $name =~ s/\//_sl_/g;
                                        $name =~ s/\./_dt_/g;
                                        $name =~ s/\@/_at_/g;
                                        $name =~ s/'/_qt_/g;
                                        $name =~ s/\[/_ls_/g;
                                        $name =~ s/\]/_rs_/g;
                                        $name =~ s/=/_eq_/g;
                                        $name =~ s/:/_co_/g;
                                        $name =~ s/\ /_/g;
                                        $tests{$name} = { addrObj => $addrObj };
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return %tests;
}

sub gen_spec_tests {
    my ( $this, $spec ) = @_;
    my %tests;

    while ( my ( $testname, $test ) = each %{$spec} ) {
        $tests{$testname} = {
            addrObj    => Foswiki::Address->new( %{ $test->{atoms} } ),
            string     => $test->{string},
            type       => $test->{type},
            expectfail => $test->{expectfail}
        };
    }

    return %tests;
}

sub test_meta1 {
    my ($this) = @_;
    my $addrObj = Foswiki::Address->new(
        webs  => [ $test_web, 'SubWeb' ],
        topic => 'Topic',
        rev   => '2',
        part  => 'META',
        subpart => [ 'FIELD', { name => 'Colour' }, 'value' ]
    );
    my $parsedaddrObj = Foswiki::Address->new(
        string  => $addrObj->stringify(),
        existAs => [qw(file meta topic)]
    );

    ASSERT( $parsedaddrObj->equiv($addrObj) );

    return;
}

sub test_meta2 {
    my ($this) = @_;
    my $addrObj = Foswiki::Address->new(
        webs  => [ $test_web, 'SubWeb' ],
        topic => 'Topic',
        rev   => '2',
        part  => 'META',
        subpart => [ 'FIELD', 2, 'value' ]
    );
    my $parsedaddrObj = Foswiki::Address->new(
        string  => $addrObj->stringify(),
        existAs => [qw(file meta topic)]
    );

    ASSERT( $parsedaddrObj->equiv($addrObj) );
    ASSERT( $parsedaddrObj->type() eq 'metakey' );
    $parsedaddrObj->subpart( [ 'FIELD', 2 ] );
    ASSERT( $parsedaddrObj->type() eq 'metamember' );
    $parsedaddrObj->subpart( ['FIELD'] );
    ASSERT( $parsedaddrObj->type() eq 'metatype' );
    $parsedaddrObj->subpart(undef);
    ASSERT( $parsedaddrObj->type() eq 'meta' );
    $parsedaddrObj->part(undef);
    ASSERT( $parsedaddrObj->type() eq 'topic' );

    return;
}

sub test_meta3 {
    my ($this) = @_;
    my $addrObj = Foswiki::Address->new(
        webs  => [ $test_web, 'SubWeb' ],
        topic => 'Topic',
        rev   => '2',
        part  => 'META',
        subpart => [ 'FIELD', { name => 'Colour' }, 'value' ]
    );
    my $parsedaddrObj = Foswiki::Address->new(
        string  => "'$test_web/SubWeb.Topic\@2'/fields[name='Colour'].value",
        existAs => [qw(file meta topic)]
    );

    ASSERT( $parsedaddrObj->equiv($addrObj) );
    ASSERT( $parsedaddrObj->type() eq 'metakey' );

    return;
}

sub test_meta4 {
    my ($this) = @_;
    my $addrObj = Foswiki::Address->new(
        webs  => [ $test_web, 'SubWeb' ],
        topic => 'Topic',
        rev   => '2',
        part  => 'META',
        subpart => [ 'FIELD', { name => 'Colour' }, 'value' ]
    );
    my $parsedaddrObj = Foswiki::Address->new(
        string  => "'$test_web/SubWeb.Topic\@2'/Colour",
        existAs => [qw(file meta topic)]
    );

    ASSERT( $parsedaddrObj->equiv($addrObj) );
    ASSERT( $parsedaddrObj->type() eq 'metakey' );

    return;
}

sub test_timing_normaliseWebTopicName {
    my ($this) = @_;
    my $web;
    my $topic;
    my $benchmark = timeit(
        15000,
        sub {
            ( $web, $topic ) =
              Foswiki::Func::normalizeWebTopicName( '', 'Web/SubWeb.Topic' );
        }
    );

    print timestr($benchmark) . "\n";

    return;
}

sub test_timing_normaliseWebTopicName_default {
    my ($this) = @_;
    my $web;
    my $topic;
    my $benchmark = timeit(
        20000,
        sub {
            ( $web, $topic ) =
              Foswiki::Func::normalizeWebTopicName( 'Web/SubWeb', 'Topic' );
        }
    );

    print timestr($benchmark) . "\n";

    return;
}

sub test_timing_normaliseWebTopicName_equiv {
    my ($this) = @_;
    my $addr;
    my $benchmark = timeit(
        10000,
        sub {
            $addr = Foswiki::Address->new(
                string => 'Web/SubWeb.Topic',
                isA    => 'topic'
            );
        }
    );

    print timestr($benchmark) . "\n";

    return;
}

sub test_timing_normaliseWebTopicName_equiv_default {
    my ($this) = @_;
    my $addr;
    my $benchmark = timeit(
        10000,
        sub {
            $addr = Foswiki::Address->new(
                string => 'Topic',
                isA    => 'topic',
                web    => 'Web/SubWeb'
            );
        }
    );

    print timestr($benchmark) . "\n";

    return;
}

sub test_timing_creation {
    my ($this) = @_;
    my $addr;
    my $benchmark = timeit(
        100000,
        sub {
            $addr = Foswiki::Address->new(
                webs    => [qw(Web SubWeb)],
                topic   => 'Topic',
                part    => 'FILE',
                subpart => 'Attachment.pdf',
                rev     => 3
            );
        }
    );

    print timestr($benchmark) . "\n";

    return;
}

sub test_timing_hashref_creation {
    my ($this) = @_;
    my $addr;
    my $benchmark = timeit(
        200000,
        sub {
            $addr = {
                webs    => [qw(Web SubWeb)],
                topic   => 'Topic',
                part    => 'FILE',
                subpart => 'Attachment.pdf',
                rev     => 3
            };
        }
    );

    print timestr($benchmark) . "\n";

    return;
}

sub test_timing_reparse_default {
    my ($this) = @_;
    my $addr =
      Foswiki::Address->new( topic => 'Topic', webs => [qw(Web SubWeb)] );
    my $benchmark = timeit(
        15000,
        sub {
            $addr->parse(
                'AnotherTopic',
                isA  => 'topic',
                webs => [qw(OtherWeb OtherSubWeb)]
            );
        }
    );

    print timestr($benchmark) . "\n";

    return;
}

sub test_timing_reparse {
    my ($this) = @_;
    my $addr =
      Foswiki::Address->new( topic => 'Topic', webs => [qw(Web SubWeb)] );
    my $benchmark = timeit(
        15000,
        sub {
            $addr->parse( 'AnotherWeb/AnotherSubWeb.AnotherTopic',
                isA => 'topic', );
        }
    );

    print timestr($benchmark) . "\n";

    return;
}

1;
