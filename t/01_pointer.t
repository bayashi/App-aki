use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;

{
    my $got = result(
        ['http://example.com/json', '--pointer' => '/foo/1'],
        +{
            'content'      => sub { '{"foo": [1, 2]}' },
            'content_type' => sub { 'application/json' },
        },
    );
    is $got, 2, 'pointer';
}

done_testing;
