use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;

{
    my ($stdout, $stderr, @result) = result(
        ['http://example.com/json', '--indent' => 2],
        [
            [ 'res', 'content' => sub { '{"foo": [1, 2]}' } ],
            [ 'res', 'content_type' => sub { 'application/json' } ],
        ],
    );
    is $stdout, <<"_EXPECTED_", 'indent';
---
  foo   [
    1,
    2
  ]
---
_EXPECTED_
}

done_testing;
