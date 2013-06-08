use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;

{
    my ($stdout, $stderr, @result) = result(
        ['http://example.com/json', '--print_escape'],
        [
            [ 'res', 'content' => sub { '{"foo": "1\t2\n"}' } ],
            [ 'res', 'content_type' => sub { 'application/json' } ],
        ],
    );
    is $stdout, <<"_EXPECTED_", 'print_escape';
---
    foo   "1\\t2\\n"
---
_EXPECTED_
}

done_testing;
