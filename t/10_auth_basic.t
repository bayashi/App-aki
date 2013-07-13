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

        my $res = $req->header('authorization');

        HTTP::Response->new(
            200 => 'OK',
            ['Content-Type' => 'application/json'],
            qq|{"res": "$res"}|,
        )
    };

    my $stdout = capture_stdout {
        App::aki->run(
            $fake_httpd->endpoint,
            '--user' => "aki:yui",
        );
    };

    like $stdout, qr/^---\n/;
    like $stdout, qr/res\s+"Basic YWtpOnl1aQ=="\n/;
}

done_testing;
