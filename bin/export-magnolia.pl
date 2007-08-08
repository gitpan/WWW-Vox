#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use IO::Prompt;
use Data::Dumper;

use HTTP::Request::Common;
use LWP::UserAgent;
use XML::Simple;

use WWW::Vox;
use WWW::Vox::Auth::Cookies;


use constant COOKIES => $ENV{VOX_COOKIES} || 'vox_cookies.txt';


my ($verbose, %opts) = 0;
GetOptions(
    'username|u=s' => \$opts{user},
    'password|p=s' => \$opts{pw},
    'count=i'      => \$opts{count},
    'offset=i'     => \$opts{offset},
    'verbose|v+'   => \$verbose,
);


if (!$opts{pw}) {
    $opts{pw} = prompt "Password for $opts{user}: ", -e => '*';
}
exit if !$opts{pw};

sub get_ua {
    return LWP::UserAgent->new( agent => "wwwvox+lwp/1.0", from => 'markpasc@markpasc.org' );
}

sub get_magnolia_key {
    my $req = POST 'https://ma.gnolia.com/api/rest/1/get_key', [
        id       => $opts{user},
        password => $opts{pw},
    ];
    print $req->as_string, "\n" if $verbose > 1;
    my $ua = get_ua();
    my $resp = $ua->request($req);
    if (!$resp->is_success) {
        print "Request for ma.gnolia key failed: ", $resp->status_line, "\n";
        print $resp->content, "\n" if $verbose > 1;
        exit;
    }

    my $xml = XML::Simple->new;
    my $ref = $xml->XMLin($resp->content);
    print Data::Dumper::Dumper($ref) if $verbose > 1;
    if ($ref->{status} ne 'ok') {
        my $error = $ref->{error} || { code => 0, message => 'no error given' };
        print "Request for ma.gnolia key failed: ", $error->{code}, q{ }, $error->{message}, "\n";
        exit;
    }
    print "Got auth key, yay!\n" if $verbose;

    return $ref->{key};
}

## Set up authenticated access to Vox.
my $auth = WWW::Vox::Auth::Cookies->new( cookies => { file => COOKIES() } );
my $vox = WWW::Vox->new( auth => $auth );
print "Made a vox, yay\n" if $verbose;

## Get recent links
my @vox_links = $vox->list_assets(
    type   => 'Link',
    count  => $opts{count}  || 20,
    offset => $opts{offset} || 0,
);

my $key = get_magnolia_key();

my $ua = get_ua();
my $xml = XML::Simple->new;
LINK: for my $vox_link (@vox_links) {
    print "Got a link!\n" if $verbose > 1;

    my $req = POST 'http://ma.gnolia.com/api/rest/1/bookmarks_add', [
        api_key     => $key,
        title       => $vox_link->name,
        description => $vox_link->description,
        url         => $vox_link->href,  # note href is the special Link asset field
        private     => $vox_link->{data}->{privacy}->{visibility_ugroup_id} ? 1 : 0,
        rating      => defined $vox_link->rating ? $vox_link->rating : 0,
        tags        => join q{,}, @{ $vox_link->{data}->{tags} },
    ];
    my $res = $ua->request($req);
    if (!$res->is_success) {
        print "Could not add link '", $vox_link->name, "' to ma.gnolia: ", $req->status_line, "\n";
        exit;
    }
    print $res->content, "\n" if $verbose > 1;

    my $result = $xml->XMLin($res->content);

    if ($result->{status} ne 'ok') {
        my $error = $result->{error} || { code => 0, message => 'no error given' };

        if ($error->{code} == 1160) {
            ## The bookmark is already in the collection, which is OK.
            ## TODO: update the ma.gnolia bookmark with the vox link's info.
            print "Link '", $vox_link->name, "' was already saved in ma.gnolia; skipped\n"
                if $verbose;
            next LINK;
        }
    
        print "Could not add link '", $vox_link->name, "' to ma.gnolia: ",
            $error->{code}, q{ }, $error->{message}, "\n";
        exit;
    }

    print "Link '", $vox_link->name, "' added\n" if $verbose;
}

