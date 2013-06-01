use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;
use Data::MessagePack;

{
    my ($stdout, $stderr, @result) = result(
        ['http://example.com/json'],
        [
            [ 'res', 'content'      => sub { Data::MessagePack->pack( +{ foo => [1,2] } ) } ],
            [ 'res', 'content_type' => sub { 'application/msgpack' } ],
        ],
    );
    is $stdout, <<'_EXPECT_', 'messagepack';
---
    foo   [
        1,
        2
    ]
---
_EXPECT_
}

{
    my $hash = +{ foo => [qw/天野アキ 足立ユイ/] };
    my ($stdout, $stderr, @result) = result(
        ['http://example.com/json'],
        [
            [ 'res', 'content'      => sub { Data::MessagePack->pack($hash) } ],
            [ 'res', 'content_type' => sub { 'application/msgpack' } ],
        ],
    );
    is $stdout, <<'_EXPECT_', 'messagepack';
---
    foo   [
        "天野アキ",
        "足立ユイ"
    ]
---
_EXPECT_
}

done_testing;
