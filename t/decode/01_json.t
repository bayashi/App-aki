use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;

{
    my ($stdout, $stderr, @result) = result(
        ['http://example.com/json'],
        [
            [ 'res', 'content'      => sub { '{"foo": [1, 2]}' } ],
            [ 'res', 'content_type' => sub { 'application/json' } ],
        ],
    );
    is $stdout, <<'_EXPECT_', 'json';
---
    foo   [
        1,
        2
    ]
---
_EXPECT_
}

done_testing;
