use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;

{
    my ($stdout, $stderr, @result) = result(
        ['http://example.com/json', '--pointer' => '/foo/1'],
        [
            [ 'res', 'content' => sub { '{"foo": [1, 2]}' } ],
            [ 'res', 'content_type' => sub { 'application/json' } ],
        ],
    );
    is $stdout, "---\n2\n---\n", 'pointer';
}

done_testing;
