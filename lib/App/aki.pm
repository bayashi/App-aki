package App::aki;
use strict;
use warnings;
use Getopt::Long qw/GetOptionsFromArray/;
use LWP::UserAgent;
use HTTP::Request;
use Data::Printer qw//;

our $VERSION = '0.01';

our @DECODERS = (
    +{
        name   => 'json',
        class  => 'JSON',
        detect => sub {
            my $res = shift;
            my $ct = $res->content_type;
            return 1 if $ct =~ m!json!i || $ct =~ m!javascript!i;
        },
        decode => sub {
            my $content = shift;
            my $json = JSON->new->utf8;
            $json->decode($content);
        },
    },
    +{
        name   => 'xml',
        class  => 'XML::TreePP',
        detect => sub {
            my $res = shift;
            my $ct = $res->content_type;
            return 1 if $ct =~ m!xml!i;
        },
        decode => sub {
            my $content = shift;
            my $xml = XML::TreePP->new;
            $xml->parse($content);
        },
    },
    +{
        name   => 'yaml',
        class  => 'YAML::Syck',
        detect => sub {
            my $res = shift;
            my $ct = $res->content_type;
            return 1 if $ct =~ m!yaml!i;
        },
        decode => sub {
            my $content = shift;
            YAML::Syck::Load($content);
        },
    },
    +{
        name   => 'messagepack',
        class  => 'Data::MessagePack',
        detect => sub {
            my $res = shift;
            my $ct = $res->content_type;
            return 1 if $ct =~ m!msgpack!i;
        },
        decode => sub {
            my $content = shift;
            my $mp = Data::MessagePack->new;
            $mp->decode($content);
        },
    },
);

sub run {
    my $self = shift;
    my @argv = @_;

    my $config = +{};
    _merge_opt($config, @argv);

    my $res = _request($config);

    if ($config->{raw}) {
        print $res->content;
        exit;
    }

    my $decoded = _decode($config, $res);

    my $dump = Data::Printer::p(
        $decoded,
        return_value => 'dump',
        colored      => $config->{color},
        index        => 0,
    );
    $dump =~ s!^[^\n]+\n!!;
    $dump =~ s!}$!!;

    print $dump;
}

sub _decode {
    my ($config, $res) = @_;

    my $decoded;
    for my $decoder (@DECODERS) {
        next unless $decoder->{detect}->($res);
        _load_class( _class2path($decoder->{class}) );
        $decoded = $decoder->{decode}->($res->content);
        last;
    }

    if ($config->{pointer}) {
        require JSON::Pointer;
        $decoded = JSON::Pointer->get($decoded, $config->{pointer});
    }

    return $decoded;
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

    my $ua = LWP::UserAgent->new(
        agent   => $config->{agent} || __PACKAGE__. "/$VERSION",
        timeout => $config->{timeout},
    );
    my $req = HTTP::Request->new(
        uc($config->{method}) => $config->{url},
    );
    my $res = $ua->request($req);
    if ($res->is_success) {
        return $res;
    }
    else {
        die $res->status_line;
    }
}

sub _merge_opt {
    my ($config, @argv) = @_;

    Getopt::Long::Configure('bundling');
    GetOptionsFromArray(
        \@argv,
        'm|method=s'  => \$config->{method},
        'timeout=i'   => \$config->{timeout},
        'p|pointer=s' => \$config->{pointer},
        'agent=s'     => \$config->{agent},
        'color'       => \$config->{color},
        'raw'         => \$config->{raw},
        'h|help'      => sub {
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

<http://stedolan.github.io/jq/>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
