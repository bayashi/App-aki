use strict;
use warnings;
use App::aki;
use Test::More;
use Test::Fake::HTTPD;
use HTTP::Response;
use HTTP::Cookies;
use Capture::Tiny qw/capture_stdout/;
use File::Temp qw/tempfile/;

{
    my $fake_httpd = run_http_server {
        my $req = shift;

        my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime(time + 600);
        my $d = (qw/Sun Mon Tue Wed Thu Fri Sat/)[$wday];
        my $m = (qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/)[$mon];
        my $expire = sprintf(
            "%s, %02d-%s-%s %02d:%02d:%02d GMT",
            $d, $mday, $m, $year + 1900, $hour, $min, $sec,
        );
        #note $expire;

        HTTP::Response->new(
            200 => 'OK',
            [
                'Content-Type' => 'application/json',
                'Set-Cookie' => "mamebu=yummy; expires=$expire",
            ],
            qq|{"res": "aki"}|,
        )
    };

    my ($dummy_fh, $filename) = tempfile(
        "aki_cookie_XXXXXXXX",
        TMPDIR => 1, UNLINK => 1,
    );
    #note $filename;

    my $stdout = capture_stdout {
        App::aki->run(
            $fake_httpd->endpoint,
            '--cookie-jar' => $filename,
        );
    };

    like $stdout, qr/^---\n/;
    like $stdout, qr/res\s+"aki"\n/;

    ok -e $filename;

    open my $fh, '<', $filename;
    my $cookie_file = do { local $/; <$fh> };
    close $fh;
    #note $cookie_file;

    like $cookie_file, qr/mamebu=yummy/;
    like $cookie_file, qr/domain=/;
    like $cookie_file, qr/expires=/;

    #----- req with cookie from file
    {
        my $fake_httpd2 = run_http_server {
            my $req = shift;

            is $req->header('cookie'), 'mamebu=yummy', 'cookie';

            HTTP::Response->new(
                200 => 'OK',
                ['Content-Type' => 'application/json'],
                qq|{"res": "yui"}|,
            )
        };

        my $stdout2 = capture_stdout {
            App::aki->run(
                $fake_httpd2->endpoint,
                '--cookie' => $filename,
            );
        };

        #note $stdout2;
        like $stdout2, qr/res\s+"yui"\n/;
    }
}

done_testing;
