use strict;
use warnings;
use App::aki;
use Test::More;
use Test::Fake::HTTPD;
use HTTP::Response;
use Capture::Tiny qw/capture_stdout/;

{
    my $fake_httpd = run_http_server {
        my $req = shift;

        is $req->header('referer'), "http://example.com/referer";

        HTTP::Response->new(
            200 => 'OK',
            ['Content-Type' => 'application/json'],
            qq|{"res": "GMT6"}|,
        )
    };

    my $stdout = capture_stdout {
        App::aki->run(
            $fake_httpd->endpoint,
            '--referer' => "http://example.com/referer",
        );
    };

    like $stdout, qr/^---\n/;
    like $stdout, qr/res\s+"GMT6"\n/;
}

done_testing;
