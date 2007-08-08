#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Data::Dumper;

use WWW::Vox;
use WWW::Vox::Auth::Cookies;

eval "require WebService::YouTube;";
if ($@) {
    print "Could not load WebService::YouTube; that module is required by this script, sorry\n";
    exit;
}


use constant COOKIES => $ENV{VOX_COOKIES} || 'vox_cookies.txt';

use constant YOUTUBE_DEV_ID => 'm1APqip10c4';


my ($verbose, %opts) = 0;
GetOptions(
    'username|u=s' => \$opts{user},
    'verbose|v+'   => \$verbose,
);


## Set up authenticated access to Vox.
my $auth = WWW::Vox::Auth::Cookies->new( cookies => { file => COOKIES() } );
my $vox = WWW::Vox->new( auth => $auth );
print "Made a vox, yay\n" if $verbose;

my $yt = WebService::YouTube::Videos->new({ dev_id => YOUTUBE_DEV_ID() });
my $url = WebService::YouTube::Util->rest_uri( YOUTUBE_DEV_ID(),
    'youtube.users.list_favorite_videos', { user => $opts{user} } );
my $res = $yt->ua->get($url);
if (!$res->is_success) {
    print "Could not fetch favorite videos; got a " . $res->status_line . "\n";
    exit;
}
my @videos = $yt->parse_xml($res->content);

VIDEO: for my $v (@videos) {
    print "Got a video!\n" if $verbose > 1;
    my ($result) = $vox->search(
        type    => 'Video',
        conduit => 'YouTube',
        query   => $v->id,  # searching for the id should magically find it
        locale  => 'en_US',
    );

    print "Got search result from Vox: ", Data::Dumper::Dumper([ $result ]) if $verbose > 1;
    if (!$result) {
        print "No videos found with id " . $v->id . "\n";
        next VIDEO;
    }

    my $asset = $result->create_asset();
}

