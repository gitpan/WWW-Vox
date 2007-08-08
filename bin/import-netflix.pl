#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use IO::Prompt;
use Data::Dumper;

use WWW::Mechanize;
use WWW::Vox;
use WWW::Vox::Auth::Cookies;


use constant COOKIES => $ENV{VOX_COOKIES} || 'vox_cookies.txt';


my ($verbose, %opts) = 0;
GetOptions(
    'username|u=s' => \$opts{nfx_user},
    'password|p=s' => \$opts{nfx_pw},
    'verbose|v+'   => \$verbose,
);


if (!$opts{nfx_pw}) {
    $opts{nfx_pw} = prompt "Password for $opts{nfx_user}: ", -e => '*';
}
exit if !$opts{nfx_pw};


## Set up authenticated access to Vox.
my $auth = WWW::Vox::Auth::Cookies->new( cookies => { file => COOKIES() } );
my $vox = WWW::Vox->new( auth => $auth );
print "Made a vox, yay\n" if $verbose;


my $mech = WWW::Mechanize->new;
$mech->get('http://www.netflix.com/Login');
$mech->submit_form(
    fields => {
        email     => $opts{nfx_user},
        password1 => $opts{nfx_pw},
    },
);
if ($mech->content =~ m{ Member\sSign\sIn }xms) {
    print "Could not log in to Netflix (invalid password?)\n";
    exit;
}
print $mech->content if $verbose > 2;
print "Signed in, yay\n" if $verbose;


my ($page_num, $last_page, @page_ratings) = 0;

my $iter = sub {
    return shift @page_ratings if @page_ratings;
    print "Oops, out of movies from that page\n" if $verbose;

    ## Out of movies on this page, and we already hit the last page. Done!
    return if $last_page;

    ## Oops, out of movies on this page. Get a new page.
    print "Fetching a new page\n" if $verbose;
    $mech->get('http://www.netflix.com/MoviesYouveSeen?pageNum=' . ++$page_num);
    my $page_content = $mech->content;
    print $page_content if $verbose > 2;
    $last_page = 1 if $mech->content !~ m{ id="nextBtn" }xms;
    while ($page_content =~ m{ netflix\.com/Movie/ [^>]+ > ([^<]+) .*? stars_\d_(\d+)\.gif }xmsg) {
        my ($title, $rating) = ($1, $2);
        $rating = $rating / 10.0;
        print "Found $title\n" if $verbose > 1;
        push @page_ratings, { title => $title, rating => $rating };
    }
    print "Found ", scalar @page_ratings, " movies\n" if $verbose;

    return shift @page_ratings;
};


MOVIE: while(my $movie = $iter->()) {
    print "Got a movie!\n" if $verbose > 1;
    my ($result) = $vox->search(
        type    => 'Video',
        conduit => 'Amazon',
        query   => $movie->{title},
        locale  => 'en_US',
    );

    print "Got search result from Vox: ", Data::Dumper::Dumper([ $result ]) if $verbose > 1;
    if (!$result) {
        print "No titles found for '" . $movie->{title} . "'\n";
        next MOVIE;
    }

    ## TODO: ask about the other results if 'no'.
    next if !prompt("For '" . $movie->{title} . ",' add '" .
        $result->name ."' with rating ". $movie->{rating} ."? ",
        '-y1');

    my $asset = $result->create_asset();
    $asset->{data}->{rating} = $movie->{rating};
    $asset->update();
}

