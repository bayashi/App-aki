use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;

{
    my @mocks = (
        [ 'res', 'content' => sub { '{"foo": [1, 2]}' } ],
        [ 'res', 'content_type' => sub { 'application/json' } ],
    );
    my ($stdout, $stderr, @result) = result(
        ['http://example.com/json'],
        \@mocks,
    );
    my ($stdout_colored, $stderr_colored, @result_colored) = result(
        ['http://example.com/json', '--rc' => 'share/.akirc'],
        \@mocks,
    );
    unlike $stdout, qr/\e/, 'no_color';
    like $stdout_colored, qr/\e/, 'rc_colored';
    ok (length $stdout < length $stdout_colored);
}

done_testing;
