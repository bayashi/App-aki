use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;

{
    my ($stdout, $stderr, @result) = result(
        ['http://example.com/json'],
        [
            [ 'res', 'content'      => sub {
                                    return <<_YAML_;
foo:
    - 1
    - 2
_YAML_
            } ],
            [ 'res', 'content_type' => sub { 'application/yaml' } ],
        ],
    );
    is $stdout, <<'_EXPECT_', 'yaml';
---
    foo   [
        1,
        2
    ]
---
_EXPECT_
}

done_testing;
