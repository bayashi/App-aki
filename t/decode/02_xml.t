use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;

{
    my ($stdout, $stderr, @result) = result(
        ['http://example.com/json'],
        [
            [ 'res', 'content'      => sub {
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
            } ],
            [ 'res', 'content_type' => sub { 'application/xml' } ],
        ],
    );
    is $stdout, <<'_EXPECT_', 'xml';
---
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
---
_EXPECT_
}

{
    my ($stdout, $stderr, @result) = result(
        ['http://example.com/json'],
        [
            [ 'res', 'content'      => sub {
                                    return <<_XML_;
<?xml version="1.0" encoding="UTF-8"?>
<members>
<member>
<id>001</id>
<name>天野アキ</name>
</member>
<member>
<id>002</id>
<name>足立ユイ</name>
</member>
</members>
_XML_
            } ],
            [ 'res', 'content_type' => sub { 'application/xml' } ],
        ],
    );
    is $stdout, <<'_EXPECT_', 'xml';
---
    members   {
        member   [
            {
                id     001,
                name   "天野アキ"
            },
            {
                id     002,
                name   "足立ユイ"
            }
        ]
    }
---
_EXPECT_
}

done_testing;
