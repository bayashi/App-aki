use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;
use Test::Mock::LWP;
use Test::Mock::HTTP::Request;

{
    $Mock_ua->mock(
        'default_headers' => sub { Mock::HTTP::Headers->new },
    );
    $Mock_req->mock(
        'as_string' => sub { 'GET http://example.com/json' },
    );

    my $got = result(
        ['http://example.com/json', '--verbose'],
        +{
            'content'      => sub { '{"foo": [1, 2]}' },
            'content_type' => sub { 'application/json' },
            'header'       => sub { 'application/json' },
            'status_line'  => sub { '200 OK' },
        },
    );
    is $got, <<"_EXPECT_", 'verbose';
[request]
GET http://example.com/json
[headers]
User-Agent: yui
[response]
200 OK
[response content_type]
application/json
[response content length]
15
[decode class]
JSON
---
    foo   [
        1,
        2
    ]
---
_EXPECT_
}

done_testing;

package Mock::HTTP::Headers;
use strict;
use warnings;

sub new { bless +{}, $_[0]; }
sub as_string { 'User-Agent: yui' }
