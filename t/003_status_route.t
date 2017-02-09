use strict;
use warnings;
use Data::Dumper;

use Bartender;
use Test::More tests => 2;
use Plack::Test;
use HTTP::Request::Common;
use JSON ();

my $app = Bartender->to_app;
my $test = Plack::Test->create($app);
my $res  = $test->request( GET '/status?dossier=foo&projetId=bar' );
ok( $res->is_success, '[GET /status] successful' );
my $compilation = JSON::decode_json( $res->content );
is( $compilation->{status}, 'NONE', '[GET /status NONE] successful' );

