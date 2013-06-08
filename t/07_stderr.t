use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;

{
    my ($stdout, $stderr, @result) = result(
        ['http://example.com/json', "--stderr"],
        [
            [ 'ua',  'env_proxy' => sub { 1 } ],
            [ 'res', 'content' => sub { '{"foo": 1}' } ],
            [ 'res', 'content_type' => sub { 'application/json' } ],
        ],
    );
    is $stderr, <<"_EXPECTED_", 'stderr';
---
    foo   1
---
_EXPECTED_
}

done_testing;
