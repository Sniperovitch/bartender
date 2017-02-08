package Bartender;
use Dancer2;
use Data::Dumper;
use POSIX ();

our $VERSION = '0.1';

get '/shake' => sub {
    my %param = params;

    my $opt_dossier = $param{dossier};
    my $opt_base   = $param{projetPadPrincipal};
    my $opt_garde  = $param{projetPadGarde};
    my $opt_projet = $param{projetId};
    my $cocktail = config->{cocktail}{binary};
    if(not defined $cocktail) {
        my $error->{message} = "cocktail:binary n'est pas configuré dans config.yml";
        return template 'error', $error;
    }
    elsif(not -x $cocktail) {
        my $error->{message} = "cocktail$cocktail n'est pas executable";
        return template 'error', $error;
    }
    system("$cocktail -d $opt_dossier -b '$opt_base' -g '$opt_garde' -p $opt_projet &");
    redirect request->referer;
};


get '/status' => sub {
    my %param = params;
    my $opt_dossier = $param{dossier};
    my $opt_projet  = $param{projetId};

    my $cocktail_store = config->{cocktail}{store};
    die unless -d $cocktail_store;
    my $compilation_status;
    if(-e "$cocktail_store/$opt_dossier/$opt_projet.lock") {
        $compilation_status = "En cours de compilation...";
    }
    elsif(-e "$cocktail_store/$opt_dossier/$opt_projet.pdf") {
        my @stat = stat "$cocktail_store/$opt_dossier/$opt_projet.pdf";
        my $ctime = $stat[10];
        my $date_time = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($ctime) );
        $compilation_status = $date_time;
    }
    else {
        $compilation_status = "Aucune compilation.";
    }

    header 'Content-Type' => 'application/json';
    return to_json { text => $compilation_status };
};


true;
