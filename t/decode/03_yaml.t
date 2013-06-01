use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;

{
    my $got = result(
        ['http://example.com/json'],
        +{
            'content'      => sub {
                                    return <<_YAML_;
foo:
    - 1
    - 2
_YAML_
            },
            'content_type' => sub { 'application/yaml' },
        },
    );
    is $got, <<'_EXPECT_', 'yaml';
---
    foo   [
        1,
        2
    ]
---
_EXPECT_
}

done_testing;
