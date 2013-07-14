package t::akiUtil;
use strict;
use warnings;
use Test::Mock::LWP;
use Capture::Tiny qw/capture/;
use App::aki;
use parent qw/Exporter/;
our @EXPORT_OK = qw/
    result
/;

sub result {
    my ($cmd_args, $mock_args) = @_;

    for my $r (@{$mock_args}) {
        my $mock = shift @{$r};
        my $mock_obj = ($mock eq 'res') ? $Mock_response
                     : ($mock eq 'req') ? $Mock_request  : $Mock_ua;
        $mock_obj->mock(@{$r});
    }

    my ($stdout, $stderr, @result) = capture {
        App::aki->run(@{$cmd_args});
    };

    return($stdout, $stderr, @result);
}

1;
