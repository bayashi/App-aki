package App::aki;
use strict;
use warnings;
use Getopt::Long qw/GetOptionsFromArray/;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Cookies;
use Data::Printer qw//;
use Encode qw//;
use File::Spec;
use Config::CmdRC '.akirc';

our $VERSION = '0.08';

# Every decode routine MUST return the UNICODE string.
our %DECODERS = (
    json => +{
        class  => 'JSON',
        detect => sub {
            my $res = shift;
            my $ct = $res->content_type;
            return 1 if $ct =~ m!json!i;
        },
        decode => sub {
            my $content = shift;
            my $json = JSON->new->utf8;
            $json->decode($content);
        },
    },
    xml => +{
        class  => 'XML::TreePP',
        detect => sub {
            my $res = shift;
            my $ct = $res->content_type;
            return 1 if $ct =~ m!xml!i;
        },
        decode => sub {
            my $content = shift;
            my $xml = XML::TreePP->new(utf8_flag => 1);
            $xml->parse($content);
        },
    },
    yaml => +{
        class  => 'YAML::Syck',
        detect => sub {
            my $res = shift;
            my $ct = $res->content_type;
            return 1 if $ct =~ m!yaml!i;
        },
        decode => sub {
            my $content = shift;
            $YAML::Syck::ImplicitUnicode = 1;
            YAML::Syck::Load($content);
        },
    },
    messagepack => +{
        class  => 'Data::MessagePack',
        detect => sub {
            my $res = shift;
            my $ct = $res->content_type;
            return 1 if $ct =~ m!msgpack!i;
        },
        decode => sub {
            my $content = shift;
            my $mp = Data::MessagePack->new->utf8;
            $mp->decode($content);
        },
    },
);

sub run {
    my $self = shift;
    my @argv = @_;

    my $config = RC();
    _merge_opt($config, @argv);

    my $res = _request($config);

    if ($config->{cookie_jar}) {
        my $cookie_jar = HTTP::Cookies->new;
        $cookie_jar->extract_cookies($res);
        $cookie_jar->save($config->{cookie_jar});
    }

    if ($config->{raw}) {
        print $res->content;
        exit;
    }

    my $decoded = _decode($config, $res);
    my $dump    = _dumper($config, $decoded);

    my $output = Encode::encode($config->{out_enc}, "---\n$dump\n---\n");
    if ($config->{stderr}) {
        print STDERR $output;
    }
    else {
        print STDOUT $output;
    }
}

sub _dumper {
    my ($config, $hash) = @_;

    my $dump = Data::Printer::p(
        $hash,
        return_value  => 'dump',
        colored       => $config->{color},
        index         => 0,
        print_escapes => $config->{print_escapes},
        indent        => $config->{indent},
    );
    $dump =~ s!^[^\n]+\n!!;
    $dump =~ s![\r\n]}$!!;

    return $dump;
}

sub _decode {
    my ($config, $res) = @_;

    my $decoded = _decoder($config, $res);

    if ($decoded && $config->{pointer}) {
        require JSON::Pointer;
        $decoded = JSON::Pointer->get($decoded, $config->{pointer});
    }

    unless ($decoded) {
        _error("could not decode the content.");
    }

    return $decoded;
}

sub _decoder {
    my ($config, $res) = @_;

    my $decoded;
    if ( my $decoder = $DECODERS{ lc($config->{decoder} || '') } ) {
        $decoded = _decoding($config, $decoder, $res);
    }
    else {
        for my $name (keys %DECODERS) {
            my $decoder = $DECODERS{$name};
            next unless $decoder->{detect}->($res);
            $decoded = _decoding($config, $decoder, $res);
            last;
        }
    }
    return $decoded;
}

sub _decoding {
    my ($config, $decoder, $res) = @_;

    _load_class( _class2path($decoder->{class}) );
    _show_verbose('decode class', $decoder->{class}) if $config->{verbose};
    my $content = $res->content;
    if ($config->{in_enc} !~ m!^utf\-?8$!i) {
        Encode::from_to($content, $config->{in_enc} => 'utf8');
    }
    return $decoder->{decode}->($content);
}

sub _error {
    my $msg = shift;

    warn "ERROR: $msg\n";
    exit;
}

sub _load_class {
    my $path = shift;

    eval {
        require $path;
        $path->import;
    };
    die $@ if $@;
}

sub _class2path {
    my $class = shift;

    $class  =~ s!::!/!g;
    $class .= '.pm';

    return $class;
}

sub _request {
    my $config = shift;

    my ($ua, $req) = _prepare_request($config);

    if ($config->{verbose}) {
        _show_verbose('request', $req->as_string);
        _show_verbose('headers', $ua->default_headers->as_string);
    }

    my $res = $ua->request($req);
    if ($res->is_success) {
        if ($config->{verbose}) {
            _show_verbose('response', $res->status_line);
            _show_verbose('response content_type', $res->header('Content_Type'));
            _show_verbose('response content length', length $res->content);
        }
        return $res;
    }
    else {
        die $res->status_line;
    }
}

sub _prepare_request {
    my $config = shift;

    my $ua = LWP::UserAgent->new(
        agent   => $config->{agent} || __PACKAGE__. "/$VERSION",
        timeout => $config->{timeout},
    );
    if ($config->{header} && ref $config->{header} eq 'ARRAY') {
        for my $h (@{$config->{header}}) {
            my ($field, $value) = split /:\s+?/, $h;
            $ua->default_header($field => $value);
        }
    }
    if ($config->{referer}) {
        $ua->default_header(referer => $config->{referer});
    }
    $ua->env_proxy;
    my $req = HTTP::Request->new(
        uc($config->{method}) => $config->{url},
    );

    if ($config->{user}) {
        my ($user, $passwd) = split /:/, $config->{user};
        $req->authorization_basic($user, $passwd);
    }

    if ($config->{cookie}) {
        $ua->cookie_jar({ file => $config->{cookie} });
    }

    return($ua, $req);
}

sub _show_verbose {
    my ($label, $line) = @_;

    $line =~ s![\r\n]+$!!;
    print "[$label]\n$line\n";
}

sub _merge_opt {
    my ($config, @argv) = @_;

    Getopt::Long::Configure('bundling');
    GetOptionsFromArray(
        \@argv,
        'd|decoder=s'   => \$config->{decoder},
        'm|method=s'    => \$config->{method},
        'timeout=i'     => \$config->{timeout},
        'H|header=s@'   => \$config->{header},
        'e|referer=s'   => \$config->{referer},
        'b|cookie=s'    => \$config->{cookie},
        'c|cookie-jar=s' => \$config->{cookie_jar},
        'u|user=s'      => \$config->{user},
        'p|pointer=s'   => \$config->{pointer},
        'ie|in-enc=s'   => \$config->{in_enc},
        'oe|out-enc=s'  => \$config->{out_enc},
        'agent=s'       => \$config->{agent},
        'color'         => \$config->{color},
        'print_escapes' => \$config->{print_escapes},
        'stderr'        => \$config->{stderr},
        'indent=i'      => \$config->{indent},
        'raw'           => \$config->{raw},
        'verbose'       => \$config->{verbose},
#        'rc=s'          => \$config->{rc},
        'h|help'        => sub {
            _show_usage(1);
        },
        'v|version'   => sub {
            print "aki $VERSION\n";
            exit 1;
        },
    ) or _show_usage(2);

    $config->{agent}   ||= "aki/$VERSION";
    $config->{method}  ||= 'GET';
    $config->{timeout} ||= 10;
    $config->{color}   ||= 0;

    $config->{out_enc} ||= 'utf8';
    $config->{in_enc}  ||= 'utf8';

    $config->{indent}  ||= 4;

    $config->{url} = shift @argv;
}

sub _show_usage {
    my $exitval = shift;

    require Pod::Usage;
    Pod::Usage::pod2usage($exitval);
}

1;

__END__

=head1 NAME

App::aki - The command-line data processor for web content


=head1 SYNOPSIS

See: L<aki> command.

    use App::aki;
    App::aki->run(@args);


=head1 DESCRIPTION

App::aki


=head1 METHODS

=head2 run

execute process


=head1 REPOSITORY

App::aki is hosted on github
<http://github.com/bayashi/App-aki>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

aki was inspired from this tool.
<http://stedolan.github.io/jq/>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
