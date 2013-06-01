use strict;
use warnings;
use t::akiUtil qw/result/;
use Test::More;

use Encode qw//;

my $eucjp_json = '{"天野アキ": "能年玲奈"}';
Encode::from_to($eucjp_json, 'utf8' => 'eucjp');

my $cp932_expect = '    天野アキ   "能年玲奈"';
Encode::from_to($cp932_expect, 'utf8' => 'cp932');

{
    my ($stdout, $stderr, @result) = result(
        ['http://example.com/json', '--in-enc' => 'eucjp', '--out-enc' => 'cp932'],
        [
            [ 'ua',  'default_headers' => sub { Mock::HTTP::Headers->new } ],
            [ 'req', 'as_string'       => sub { 'GET http://example.com/json' } ],
            [ 'res', 'content' => sub { "$eucjp_json" } ],
            [ 'res', 'content_type' => sub { 'application/json' } ],
        ],
    );
    is $stdout, "---\n$cp932_expect\n---\n", 'in-out encoding';
}

done_testing;

package Mock::HTTP::Headers;
use strict;
use warnings;

sub new { bless +{}, $_[0]; }
sub as_string { 'User-Agent: yui' }
