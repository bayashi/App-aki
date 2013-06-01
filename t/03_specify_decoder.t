use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;

{
    my ($stdout, $stderr, @result) = result(
        ['http://example.com/foo', '--decoder' => 'json'],
        [
            [ 'res', 'content'      => sub { '{"foo": [1, 2]}' } ],
            [ 'res', 'content_type' => sub { 'text/plain' } ],
        ],
    );
    is $stdout, <<'_EXPECT_', 'specify json';
---
    foo   [
        1,
        2
    ]
---
_EXPECT_
}

done_testing;
