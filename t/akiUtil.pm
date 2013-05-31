package t::akiUtil;
use strict;
use warnings;
use Test::Mock::LWP;
use Test::Mock::HTTP::Response;
use Capture::Tiny qw/capture_stdout/;
use App::aki;
use parent qw/Exporter/;
our @EXPORT_OK = qw/
    result
/;

sub result {
    my ($cmd_args, $mock_args) = @_;

    for my $key (keys %{$mock_args}) {
        $Mock_response->mock(
            $key => $mock_args->{$key},
        );
    }

    my $stdout = capture_stdout {
        App::aki->run(@{$cmd_args});
    };

    return $stdout;
}

