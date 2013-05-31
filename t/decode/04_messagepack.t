use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;
use Data::MessagePack;

{
    my $got = result(
        ['http://example.com/json'],
        +{
            'content'      => sub { Data::MessagePack->pack( +{ foo => [1,2] } ) },
            'content_type' => sub { 'application/msgpack' },
        },
    );
    is $got, <<'_EXPECT_', 'messagepack';
    foo   [
        1,
        2
    ]
_EXPECT_
}

done_testing;
