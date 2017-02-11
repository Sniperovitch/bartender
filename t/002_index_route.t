use strict;
use warnings;
use Data::Dumper;

use Bartender;
use Test::More tests => 3;
use Plack::Test;
use HTTP::Request::Common;

my $app = Bartender->to_app;
is( ref $app, 'CODE', 'Got app' );
my $test = Plack::Test->create($app);
my $res  = $test->request( GET '/' );
ok( $res->is_success, '[GET /] successful' );
is( $res->content, "Welcome on Bartender", '[GET / content] successful' );

