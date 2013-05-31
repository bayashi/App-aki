use Test::Perl::Metrics::Lite (
    -mccabe_complexity => 10,
    -loc => 85,
    -except_dir  => [
    ],
    -except_file => [
    ],
);

all_metrics_ok();
