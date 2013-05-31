use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;

{
    my $got = result(
        ['http://example.com/json'],
        +{
            'content'      => sub { '{"foo": [1, 2]}' },
            'content_type' => sub { 'application/json' },
        },
    );
    is $got, <<'_EXPECT_', 'json';
    foo   [
        1,
        2
    ]
_EXPECT_
}

done_testing;
