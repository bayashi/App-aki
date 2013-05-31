use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;

{
    my $got = result(
        ['http://example.com/json'],
        +{
            'content'      => sub {
                                    return <<_XML_;
<?xml version="1.0" encoding="UTF-8"?>
<members>
<member>
<id>001</id>
<name>aki</name>
</member>
<member>
<id>002</id>
<name>yui</name>
</member>
</members>
_XML_
            },
            'content_type' => sub { 'application/xml' },
        },
    );
    is $got, <<'_EXPECT_', 'xml';
    members   {
        member   [
            {
                id     001,
                name   "aki"
            },
            {
                id     002,
                name   "yui"
            }
        ]
    }
_EXPECT_
}

done_testing;
