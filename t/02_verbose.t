use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;

{
    my ($stdout, $stderr, @result) = result(
        ['http://example.com/json', '--verbose'],
        [
            [ 'ua',  'default_headers' => sub { Mock::HTTP::Headers->new } ],
            [ 'req', 'as_string'       => sub { 'GET http://example.com/json' } ],
            [ 'res', 'content'      => sub { '{"foo": [1, 2]}' } ],
            [ 'res', 'content_type' => sub { 'application/json' } ],
            [ 'res', 'header'       => sub { 'application/json' } ],
            [ 'res', 'status_line'  => sub { '200 OK' } ],
        ],
    );
    is $stdout, <<"_EXPECT_", 'verbose';
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
