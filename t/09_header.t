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

        my $res = $req->header('x-aki');

        HTTP::Response->new(
            200 => 'OK',
            ['Content-Type' => 'application/json'],
            qq|{"res": "$res"}|,
        )
    };

    my $expect = "naraku";

    my $stdout = capture_stdout {
        App::aki->run(
            $fake_httpd->endpoint,
            '--header' => "X-Aki: $expect",
        );
    };

    like $stdout, qr/^---\n/;
    like $stdout, qr/res\s+"$expect"\n/;
}

{
    my $fake_httpd = run_http_server {
        my $req = shift;

        my $res  = $req->header('x-aki');
        my $res2 = $req->header('x-yui');

        HTTP::Response->new(
            200 => 'OK',
            ['Content-Type' => 'application/json'],
            qq|{"res": "$res:$res2"}|,
        )
    };

    my $expect  = "naraku";
    my $expect2 = "yankee";

    my $stdout = capture_stdout {
        App::aki->run(
            $fake_httpd->endpoint,
            '--header' => "X-Aki: $expect",
            '--header' => "X-Yui: $expect2",
        );
    };

    like $stdout, qr/^---\n/;
    like $stdout, qr/res\s+"$expect:$expect2"\n/;
}

done_testing;
