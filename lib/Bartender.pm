package Bartender;
use Dancer2;
use Data::Dumper;
use POSIX ();
use URI::Encode ();

our $VERSION = '0.1';
die "config.yml not loaded" unless defined config->{appname};

get '/' => sub {
    return "Welcome on " . config->{appname};
};

get '/shake' => sub {
    my %param = params;
    my $error = {};

    my $opt_dossier = $param{dossier};
    my $opt_base    = $param{projetPadPrincipal};
    my $opt_garde   = $param{projetPadGarde};
    my $opt_projet  = $param{projetId};

    for($opt_dossier, $opt_projet) {
        if( m{[^a-zA-Z0-9_-]} ) {
            $error->{message} .= qq{"$_" est incorrect.};
        }
    }

    for($opt_base, $opt_garde) {
        if(not m/^https?:\/\/pad\.exegetes\.eu\.org\/(?:p|group\.html\/\d+\/pad\.html)\/g\./i ) {
            $error->{message} .= qq{"$_" est incorrect.};
        }
    }

    my $cocktail_binary = config->{cocktail}{binary};
    if(not defined $cocktail_binary) {
        $error->{message} .= qq{"cocktail:binary" n'est pas configuré dans config.yml};
    }
    elsif(not -x $cocktail_binary) {
        $error->{message} .= qq{"cocktail:binary" "$cocktail_binary" n'est pas executable};
    }

    if($error->{message}) {
        return template 'error', $error;
    }

    my $uri_encode_opts = {
        encode_reserved => 1,
        double_encode   => 0,
    };
    $opt_base  = URI::Encode::uri_encode($opt_base,  $uri_encode_opts);
    $opt_garde = URI::Encode::uri_encode($opt_garde, $uri_encode_opts);
    system("$cocktail_binary -d $opt_dossier -b '$opt_base' -g '$opt_garde' -p $opt_projet &");
    redirect request->referer;
};


get '/status' => sub {
    my %param = params;
    my $error = {};
    my $opt_dossier = $param{dossier};
    my $opt_projet  = $param{projetId};

    my $cocktail_store = config->{cocktail}{store};
    if(not defined $cocktail_store) {
        $error->{message} .= qq{"cocktail:store" n'est pas configuré dans config.yml};
    }

    if(not defined $opt_projet) {
        $error->{message} .= qq{arg:projetId est incorrect};
    }

    if($error->{message}) {
        return template 'error', $error;
    }

    my $lock_filename = "$cocktail_store/$opt_dossier/$opt_projet.lock";
    my $pdf_filename  = "$cocktail_store/$opt_dossier/$opt_projet.pdf";

    my ($compilation_status, $compilation_text);
    if(-e $lock_filename) {
        my $date_time = _get_datetime_for($lock_filename);
        $compilation_text = "En cours de compilation depuis $date_time";
        $compilation_status = 'IN PROGRESS';
    }
    elsif(-e $pdf_filename) {
        my $date_time = _get_datetime_for($pdf_filename);
        $compilation_text = $date_time;
        $compilation_status = 'COMPLETED';
    }
    else {
        $compilation_text = "Aucune compilation.";
        $compilation_status = 'NONE';
    }

    header 'Content-Type' => 'application/json';
    return to_json { text => $compilation_text, status => $compilation_status };
};

sub _get_datetime_for {
    my $filename = shift;
    return unless -e $filename;

    my @stat = stat $filename;
    my $ctime = $stat[10];
    my $date_time = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($ctime) );
    return $date_time;
}

true;

