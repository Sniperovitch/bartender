package Bartender;
use Dancer2;
use Data::Dumper;
use POSIX ();

our $VERSION = '0.1';

#get '/' => sub {
#    send_file '/index.html';
#};


get '/shake' => sub {
    my %param = params;

    my $opt_dossier = $param{dossier};
    my $opt_base   = $param{projetPadPrincipal};
    my $opt_garde  = $param{projetPadGarde};
    my $opt_projet = $param{projetId};

    system("/home/sniperovitch/cocktail/cocktail -d $opt_dossier -b '$opt_base' -g '$opt_garde' -p $opt_projet &");
     redirect request-referer;
#    send_file '/index.html';
};


get '/status' => sub {
    my %param = params;
    my $opt_dossier = $param{dossier};
    my $opt_projet  = $param{projetId};

    my $compilation_status;
    if(-e "/tmp/exegetes/$opt_dossier/$opt_projet.lock") {
        $compilation_status = "En cours de compilation...";
    }
    elsif(-e "/tmp/exegetes/$opt_dossier/$opt_projet.pdf") {
        my @stat = stat "/tmp/exegetes/$opt_dossier/$opt_projet.pdf";
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
